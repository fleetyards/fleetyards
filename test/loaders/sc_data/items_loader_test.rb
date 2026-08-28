# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class ItemsLoaderTest < ActiveSupport::TestCase
      include HangarImportFixtures
      include ScDataFixtureTree

      setup do
        clean_loader_tables
      end

      def items_loader
        fixture_loader(::ScData::Loader::ItemsLoader)
      end

      # Deliberately the real tree, and the only test here that reads it: an
      # export whose shape moved -- a renamed field, a category that stopped
      # being written -- shows up as a load that stops producing components,
      # and no curated fixture can tell you that. Everything below runs
      # against test/fixtures/sc_data, because a load of the real tree walks
      # ~7,800 files and writes ~7,300 components per call.
      test "#all loads data from game files" do
        loader = ::ScData::Loader::ItemsLoader.new

        initial = Component.where.not(version: nil).count

        loader.all

        assert_operator Component.where.not(version: nil).count - initial, :>=, 5000
      end

      # A component is the same component across builds. The loader used to key
      # on (sc_key, version) and add a row per import, which is how the table
      # came to hold every patch it had ever seen.
      test "#all updates the component a past build left rather than adding another" do
        stale = create(:component, sc_key: "aegs_avenger_thruster_main", version: "0.0.1-live.1", name: "Stale")

        assert_no_difference -> { Component.where(sc_key: "aegs_avenger_thruster_main").count } do
          items_loader.all
        end

        # The same row, carrying the build it has now been seen in.
        assert_equal ScData::Source.version, stale.reload.version
      end

      # A new build leaves a dropped component on its old version, so
      # current_version filters it out. Re-importing the build we are already on
      # does not: the row keeps claiming it, and every picker keeps offering it.
      test "#all stops a dropped component claiming the build it is no longer in" do
        items_loader.all

        retired = create(:component, sc_key: "gone_from_the_export", version: ScData::Source.version)
        kept = Component.where.not(id: retired.id).where(version: ScData::Source.version).first

        items_loader.all

        assert Component.exists?(retired.id), "the row has to stay for the loadouts pointing at it"
        assert_nil retired.reload.version
        assert_equal ScData::Source.version, kept.reload.version
      end

      # A paint names no artwork itself -- the picture hangs off the record its
      # manufacturer_ref points at.
      test "#all attaches the colour swatch a paint reaches through its manufacturer" do
        items_loader.all

        icon = Component.find_by(sc_key: "paint_100i_black_orange").icon

        assert_predicate icon, :attached?
        assert_equal "paint_100i_flame_black_orange_icon.png", icon.filename.to_s
      end

      # store_image is curated -- an admin upload, or what the hangar sync
      # brought in -- so a load must never write to it.
      test "#all leaves a curated store_image alone while attaching the icon" do
        items_loader.all

        component = Component.find_by(sc_key: "paint_100i_black_orange")

        assert_not_predicate component.store_image, :attached?
      end

      # Only a paint reaches a swatch this way. Every other item's manufacturer
      # is a real one, and its logo is a picture of the maker, not of the item.
      test "#all gives no icon to an item whose manufacturer is a real one" do
        items_loader.all

        assert_not_predicate Component.find_by(sc_key: "aegs_avenger_cml_chaff").icon, :attached?
      end

      # Nothing but a load writes to the icon, so a build that stops naming one
      # has to take the picture with it -- otherwise the component goes on
      # serving artwork the current export does not carry.
      test "#all drops an icon the export stopped naming" do
        items_loader.all

        component = Component.find_by(sc_key: "aegs_avenger_cml_chaff")
        component.icon.attach(
          io: File.open(Rails.root.join("test/fixtures/files/test.png")),
          filename: "test.png",
          content_type: "image/png"
        )

        items_loader.all

        assert_not_predicate component.reload.icon, :attached?
      end

      # A pass that dies partway has already committed the components it got
      # through, so the icons the export orphaned go with those updates rather
      # than wait for whichever later load happens to run to the end.
      test "#all drops the icon of a record it got through before a later item raised" do
        items_loader.all

        component = Component.find_by(sc_key: "aegs_avenger_cml_chaff")
        component.icon.attach(
          io: File.open(Rails.root.join("test/fixtures/files/test.png")),
          filename: "test.png",
          content_type: "image/png"
        )

        loader = items_loader
        items = loader.send(:load_items, "items")
        orphaned = items.find { |item| item["key"].downcase == "aegs_avenger_cml_chaff" }
        raises_later = items.find { |item| item["key"].downcase == "paint_100i_black_orange" }

        loader.stubs(:load_items).returns([orphaned, raises_later])
        loader.stubs(:attach_icon).raises("the export went bad partway through")

        assert_raises(RuntimeError) { loader.all }

        assert_not_predicate component.reload.icon, :attached?
      end

      # A path that fails to resolve is a broken parse, not a dropped picture.
      test "#all keeps the icon of a record that still names one" do
        items_loader.all

        icon = Component.find_by(sc_key: "paint_100i_black_orange").icon
        blob_id = icon.blob.id

        items_loader.all

        icon = Component.find_by(sc_key: "paint_100i_black_orange").icon

        assert_predicate icon, :attached?
        assert_equal blob_id, icon.blob.id, "an unchanged icon should not be re-attached"
      end

      # What a cargo grid holds -- its dimensions and capacity -- is written on
      # the `category: inventory` row a load itself skips, and the grid only
      # names that row's ref.
      test "#all carries the type_data of the inventory row a grid's ref names" do
        items_loader.all

        grid = Component.find_by(sc_key: "aegs_avenger_cargogrid_stalker")

        assert_equal 4, grid.type_data["capacity"]
      end
    end
  end
end
