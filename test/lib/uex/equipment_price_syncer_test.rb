# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class EquipmentPriceSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Equipment.delete_all
      ItemPrice.where(item_type: %w[Equipment Component]).delete_all
      @equipment = create_uex_priced_equipment
    end

    def sync(overrides = {})
      client = uex_client_stub({item_prices: uex_fixture("equipment_items_prices_all")}.merge(overrides))

      Uex::EquipmentPriceSyncer.new(client:).run
    end

    def prices_for(equipment)
      ItemPrice.where(item_type: "Equipment", item_id: equipment.id)
    end

    test "#run resolves an item by sc_ref rather than by name" do
      sync

      assert_equal 2500, prices_for(@equipment[:ref_match]).find_by(price_type: "sell", location: "CenterMass - Area 18").price
    end

    test "#run resolves an item by a name nothing else answers to" do
      sync

      assert_equal 1200, prices_for(@equipment[:name_match]).sole.price
    end

    test "#run keeps the cheaper sell and the better paid buy of two terminals at one location" do
      sync

      depot = prices_for(@equipment[:ref_match]).where(location: "Dumper's Depot - Area 18")

      assert_equal 2400, depot.find_by(price_type: "sell").price
      assert_equal 1100, depot.find_by(price_type: "buy").price
    end

    # Skins are hidden from the catalogue but are sold like anything else, and
    # leaving them out would report every one as a gap nobody can close.
    test "#run prices a hidden item the build we are on still carries" do
      sync

      assert_equal 3100, prices_for(@equipment[:hidden_skin]).sole.price
    end

    test "#run leaves a name several items answer to unpriced and reports it" do
      result = sync

      @equipment[:ambiguous].each { |equipment| assert_empty prices_for(equipment) }

      row, sc_keys = result.ambiguous.sole
      assert_equal "Beacon Undersuit", row["item_name"]
      assert_equal %w[beacon_undersuit_01 beacon_undersuit_01_02], sc_keys.sort
    end

    test "#run prices the item a mapping names and not its namesake" do
      sync

      assert_equal 2900, prices_for(@equipment[:mapping_match]).sole.price
      assert_empty prices_for(@equipment[:mapping_loser])
    end

    test "#run reports a mapping that points at an item that is gone" do
      @equipment[:mapping_match].destroy!

      result = sync

      row, sc_key = result.stale_mappings.sole

      assert_equal "P8-SC \"Boneyard\" SMG", row["item_name"]
      assert_equal "behr_smg_ballistic_01_white02", sc_key
      assert_empty prices_for(@equipment[:mapping_loser])
    end

    test "#run skips a price of zero and a terminal that does not sell items" do
      sync

      assert_empty prices_for(@equipment[:free])
      assert_empty ItemPrice.where(item_type: "Equipment", location: "Admin - ARC-L1")
    end

    test "#run reports gear it cannot place apart from everything else" do
      result = sync

      assert_equal ["Ghostwalker Core"], result.unknown.map { |row| row["item_name"] }
      assert_equal ["Big Benny's Noodles", "Sunrise Cooler"], result.unknown_other.map { |row| row["item_name"] }.sort
    end

    # Both syncers read one feed and write one table. Each reconciles only its
    # own item type, so a run of one must not take the other's prices as stale.
    test "#run leaves component prices alone" do
      component_price = ItemPrice.create!(
        item: create(:component, name: "Sunrise Cooler"), price_type: "sell",
        location: "CenterMass - Area 18", price: 4200
      )

      sync

      assert ItemPrice.exists?(component_price.id)
    end

    test "#run removes an equipment price the feed no longer lists" do
      sync
      stale = ItemPrice.create!(
        item: @equipment[:name_match], price_type: "sell",
        location: "Astro Armada - Area 18", price: 99
      )

      sync

      assert_not ItemPrice.exists?(stale.id)
    end

    test "#run records the day's prices as snapshots" do
      sync

      assert_equal ItemPrice.where(item_type: "Equipment").count,
        ItemPriceSnapshot.where(item_type: "Equipment", recorded_on: Date.current).count
    end

    test "#run refuses an empty price feed rather than deleting what we hold" do
      sync

      assert_raises(Uex::Error) { sync(item_prices: []) }
      assert_predicate ItemPrice.where(item_type: "Equipment"), :any?
    end

    test ".github_issue_body names the gear it cannot place and the ambiguous name" do
      body = Uex::EquipmentPriceSyncer.github_issue_body(sync)

      assert_includes body, "Ghostwalker Core"
      assert_includes body, "Beacon Undersuit"
      assert_includes body, "beacon_undersuit_01_02"
    end

    test ".github_issue_body carries nothing that moves on its own" do
      body = Uex::EquipmentPriceSyncer.github_issue_body(sync)

      assert_not_includes body, "Big Benny's Noodles"
      assert_not_includes body, "created="
      assert_not_includes body, "2500"
    end

    test ".github_issue_body names a stale mapping and what it points at" do
      result = Uex::ItemPriceSyncer::Result.new(
        created: 0, updated: 0, removed: 0, skipped_removals: 0, unknown: [], unknown_other: [], ambiguous: [],
        stale_mappings: [[{"item_name" => "ORC-mkX Core", "id_item" => 99}, "orc_mkx_core_01"]]
      )

      body = Uex::EquipmentPriceSyncer.github_issue_body(result)

      assert_includes body, "Mapped to an item that is gone"
      assert_includes body, "missing `orc_mkx_core_01`"
    end
  end
end
