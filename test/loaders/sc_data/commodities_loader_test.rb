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

      # The localization index is downcased while the game's type keys are camel
      # case, so a lookup that skips the downcase silently drops the label for
      # every multi-word type and leaves the single-word ones looking fine.
      test "every parsed commodity carries the label for its type" do
        parsed = @loader.load_items("commodities")

        assert_empty parsed.select { |commodity| commodity[:commodity_type_name].blank? }
          .map { |commodity| commodity[:sc_key] }
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

      # A new build leaves a dropped record on its old version, so
      # current_version filters it out. Re-importing the build we are already on
      # does not: the row keeps claiming it, and the picker keeps offering it.
      test "#all stops a dropped commodity claiming the build it is no longer in" do
        @loader.all

        retired = create(:commodity, sc_key: "items_commodities_gone", version: Rails.configuration.sc_data[:version])

        @loader.all

        assert Commodity.exists?(retired.id), "the row has to stay for existing references"
        assert_nil retired.reload.version
        assert_not Commodity.current_version.exists?(retired.id)
      end

      test "#all leaves the commodities still in the export on the current build" do
        @loader.all
        @loader.all

        assert_operator Commodity.current_version.count, :>=, 160
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
