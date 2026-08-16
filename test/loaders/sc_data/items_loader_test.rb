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
    end
  end
end
