# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class ItemsLoaderTest < ActiveSupport::TestCase
      test "#all loads data from game files" do
        loader = ::ScData::Loader::ItemsLoader.new

        initial = Component.where.not(version: nil).count

        loader.all

        assert_operator Component.where.not(version: nil).count - initial, :>=, 5000
      end
    end
  end
end
