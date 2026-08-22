# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class CommodityMatcherTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Commodity.delete_all
      @commodities = create_uex_fixture_commodities
      @rows = uex_fixture("commodities").index_by { |row| row["id"] }
      @matcher = Uex::CommodityMatcher.new
    end

    test "matches on name" do
      assert_equal @commodities[:name_match].id, @matcher.match(@rows[33]).id
    end

    test "matches across punctuation and case" do
      assert_equal @commodities[:punctuated_match].id, @matcher.match(@rows[24]).id
    end

    test "matches via the explicit mapping when the spelling differs" do
      assert_equal @commodities[:mapping_match].id, @matcher.match(@rows[137]).id
    end

    test "the mapping wins over a name that would resolve elsewhere" do
      decoy = create(:commodity, name: "Lunes", sc_key: "items_commodities_decoy_lunes")
      spiral = create(:commodity, name: "Lunes (Spiral Fruit)", sc_key: "items_commodities_spiral")

      matched = Uex::CommodityMatcher.new.match(@rows[145])

      assert_equal spiral.id, matched.id
      assert_not_equal decoy.id, matched.id
    end

    test "does not match a near neighbour UEX names differently" do
      assert_nil @matcher.match(@rows[186])
      assert_equal ["Organics"], @matcher.misses.map { |row| row["name"] }
    end

    test "records a miss for a commodity we do not carry" do
      assert_nil @matcher.match(@rows[999])
      assert_equal [999], @matcher.misses.map { |row| row["id"] }
    end

    # Read from a committed fixture rather than the parsed tree, which is not in
    # git and so is absent on CI. `bin/scdata parse` rewrites the fixture, so a
    # build that renames or drops a commodity shows up here as a diff.
    test "every mapping points at a commodity key the parser produces" do
      keys = JSON.parse(
        Rails.root.join("test/fixtures/sc_data/live/commodity_keys.json").read
      ).to_set

      assert_empty Uex::CommodityMatcher::MAPPINGS.values.reject { |key| keys.include?(key) }
    end
  end
end
