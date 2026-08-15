# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class CommoditiesLoaderTest < ActiveSupport::TestCase
      setup do
        Commodity.delete_all
        @loader = ::ScData::Loader::CommoditiesLoader.new
      end

      test "#all loads commodities from game files" do
        @loader.all

        assert_operator Commodity.count, :>=, 160

        sc_keys = Commodity.pluck(:sc_key)
        assert_equal sc_keys.uniq.size, sc_keys.size

        slugs = Commodity.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size
      end

      test "#all assigns a type to every commodity" do
        @loader.all

        assert_empty Commodity.where(commodity_type: nil).pluck(:name)
        assert_empty Commodity.where.not(commodity_type: Commodity::TYPES).pluck(:commodity_type)
      end

      test "#all resolves refined metals, ores and harvestables" do
        @loader.all

        assert_equal "metal", Commodity.find_by(sc_key: "items_commodities_gold")&.commodity_type
        assert_equal "metal", Commodity.find_by(sc_key: "items_commodities_iron_ore")&.commodity_type
        assert_equal "mineral", Commodity.find_by(sc_key: "items_commodities_janalite")&.commodity_type
        assert_equal "natural", Commodity.find_by(sc_key: "items_commodities_kopionhorn")&.commodity_type

        # The alloys are tagged both "alloy" and "metal" across crate records;
        # the bare commodity record settles it.
        assert_equal "alloy", Commodity.find_by(sc_key: "items_commodities_steel")&.commodity_type
      end

      test "#all is idempotent" do
        @loader.all
        count = Commodity.count

        assert_no_difference -> { Commodity.count } do
          @loader.all
        end

        assert_equal count, Commodity.count
      end

      test "#all keeps a commodity that already exists without an sc_key" do
        existing = create(:commodity, name: "Gold", sc_key: nil, commodity_type: nil)

        @loader.all

        existing.reload

        assert_equal "items_commodities_gold", existing.sc_key
        assert_equal "metal", existing.commodity_type
      end
    end
  end
end
