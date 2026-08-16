# frozen_string_literal: true

require "test_helper"
require_relative "../../support/hangar_import_fixtures"

module ScData
  module Loader
    class ItemsLoaderTest < ActiveSupport::TestCase
      include HangarImportFixtures

      setup do
        clean_loader_tables
      end

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
          ::ScData::Loader::ItemsLoader.new.all
        end

        # The same row, carrying the build it has now been seen in.
        assert_equal Rails.configuration.sc_data[:version], stale.reload.version
      end

      # A new build leaves a dropped component on its old version, so
      # current_version filters it out. Re-importing the build we are already on
      # does not: the row keeps claiming it, and every picker keeps offering it.
      test "#all stops a dropped component claiming the build it is no longer in" do
        ::ScData::Loader::ItemsLoader.new.all

        retired = create(:component, sc_key: "gone_from_the_export", version: Rails.configuration.sc_data[:version])
        kept = Component.where.not(id: retired.id).where(version: Rails.configuration.sc_data[:version]).first

        ::ScData::Loader::ItemsLoader.new.all

        assert Component.exists?(retired.id), "the row has to stay for the loadouts pointing at it"
        assert_nil retired.reload.version
        assert_equal Rails.configuration.sc_data[:version], kept.reload.version
      end
    end
  end
end
