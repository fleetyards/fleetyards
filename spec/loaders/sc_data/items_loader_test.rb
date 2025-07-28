# frozen_string_literal: true

require "test_helper"

module ScData
  class ItemsLoaderTest < ActiveSupport::TestCase
    let(:loader) { ::ScData::Loader::ItemsLoader.new }

    describe "#all" do
      it "loads data from game files" do
        assert_difference("Component.where.not(version: nil).count", 5249) do
          loader.all
        end
      end
    end
  end
end
