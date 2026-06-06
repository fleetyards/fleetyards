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
    end
  end
end
