# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class LocationsLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      setup do
        GameMissionLocation.delete_all
        LocationBuild.delete_all
        Location.delete_all
      end

      def loader
        fixture_loader(::ScData::Loader::LocationsLoader)
      end

      test "#all loads every place with a current build" do
        loader.all

        assert_equal 15, Location.count
        assert_equal Location.count, LocationBuild.current(fixture_source).distinct.count(:location_id)

        slugs = Location.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size
      end

      test "#all nests a place where it is and keeps the game's map parent beside it" do
        loader.all

        levski = Location.find_by!(sc_key: "Nyx_Levski")

        assert_equal ["Nyx System", "Nyx", "Delamar"], levski.ancestors.map(&:name).reverse
        assert_equal "NyxStar", levski.map_parent.sc_key
        assert_equal "NyxSolarSystem", levski.system.sc_key
        assert_predicate levski, :always_shown
      end

      test "#all leaves the map parent empty where it is the parent" do
        loader.all

        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        assert_equal "Stanton1", lorville.parent.sc_key
        assert_nil lorville.map_parent
        assert_predicate lorville, :shown_with_parent_only
      end

      # Both Outpost 54 facilities sit on Aberdeen, so the parent does not tell
      # them apart and the second one takes its key.
      test "#all tells places that share a name apart by their parent, then their key" do
        loader.all

        slugs = Location.where(name: "Outpost 54").order(:sc_key).pluck(:slug)

        assert_equal ["outpost-54-aberdeen", "outpost-54-miningfacility-stanton1b-sloane"], slugs
        assert_equal "lorville", Location.find_by!(sc_key: "Stanton1_Lorville").slug
      end

      # A namesake arriving in a later build, or in a ptu tree that shares these
      # rows, takes the longer slug and leaves the incumbent's URL alone.
      test "#all keeps a place's slug when a namesake appears" do
        loader.all
        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        newcomer = create(:location, name: "Lorville", parent: Location.find_by!(sc_key: "Stanton1b"))
        loader.all

        assert_equal "lorville", lorville.reload.slug
        assert_equal "lorville-aberdeen", newcomer.slug
      end

      test "#all gives a place a new slug when its name no longer reads like the old one" do
        loader.all
        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")
        lorville.update_columns(slug: "lorville-central")

        lorville.update!(name: "Lorville")

        assert_equal "lorville", lorville.slug
      end

      test "#all is idempotent" do
        loader.all
        slugs = Location.order(:sc_key).pluck(:sc_key, :slug, :parent_id, :map_parent_id)

        second = loader
        second.all

        assert_equal slugs, Location.order(:sc_key).pluck(:sc_key, :slug, :parent_id, :map_parent_id)
        assert_equal 0, second.stats[Location.name][:created]
        assert_equal 0, second.stats[Location.name][:updated]
      end

      test "#all retires a place the build dropped" do
        loader.all

        dropped = create(:location, sc_key: "Gone_Station", version: ::ScData::Source.version)

        loader.all

        assert_nil dropped.reload.version
        assert_predicate Location.find_by!(sc_key: "Nyx_Levski").version, :present?
      end

      test "#all on an empty tree retires nothing" do
        loader.all

        empty_tree_loader(::ScData::Loader::LocationsLoader).all

        assert_equal 15, Location.where.not(version: nil).count
      end
    end
  end
end
