# frozen_string_literal: true

require "test_helper"

module Rsi
  class CcuCatalogueTest < ActiveSupport::TestCase
    setup do
      @cutlass = create(:model, name: "Cutlass Black", rsi_id: 56, rsi_chassis_id: 12)
      @carrack = create(:model, name: "Carrack", rsi_id: 62, rsi_chassis_id: 29)
      @kraken = create(:model, name: "Kraken", rsi_id: 170, rsi_chassis_id: 69)
      @privateer = create(:model, name: "Kraken Privateer", rsi_id: 171, rsi_chassis_id: 69)
      @pioneer = create(:model, name: "Pioneer", rsi_id: 149, rsi_chassis_id: 51)
    end

    test "a ship upgrades reach only from its own hull's variants is reachable only from those" do
      create(:buyback_pledge, kind: "upgrade", name: "Upgrade - Kraken to Kraken Privateer",
        upgrade_from_ship_id: 170, upgrade_to_ship_id: 171)
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Cutlass Black to Carrack")

      CcuCatalogue.new.run

      assert_equal [@kraken.id], @privateer.reload.ccu_target_source_ids
      assert_not @privateer.ccu_into_from?(@cutlass)
      assert @privateer.ccu_into_from?(@kraken)
      assert_nil @carrack.reload.ccu_target_source_ids
    end

    test "an upgrade between editions of one ship is no evidence" do
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Kraken to Kraken")

      CcuCatalogue.new.run

      assert_nil @kraken.reload.ccu_target_seen_at
      assert_nil @kraken.ccu_target_source_ids
    end

    test "an upgrade from another hull lifts the limit" do
      @privateer.update!(ccu_target_source_ids: [@kraken.id])
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Kraken to Kraken Privateer")
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Carrack to Kraken Privateer")

      CcuCatalogue.new.run

      assert_nil @privateer.reload.ccu_target_source_ids
    end

    test "an admin allowing upgrades into a ship lifts the limit" do
      @privateer.update!(ccu_target_source_ids: [@kraken.id], ccu_override: "allowed")

      assert_nil @privateer.ccu_into_from_ids
      assert @privateer.ccu_into_from?(@cutlass)
    end

    test "a ship an upgrade in any hangar or buy-back leads out of or into is seen" do
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Cutlass Black to Carrack Warbond Edition")
      create(:buyback_pledge, kind: "upgrade", name: "Upgrade - Kraken to Kraken Privateer",
        upgrade_from_ship_id: 170, upgrade_to_ship_id: 171)
      now = Time.zone.parse("2026-10-30 12:00")

      CcuCatalogue.new.run(now:)

      assert_equal now, @cutlass.reload.ccu_source_seen_at
      assert_nil @cutlass.ccu_target_seen_at
      assert_equal now, @carrack.reload.ccu_target_seen_at
      assert_equal now, @kraken.reload.ccu_source_seen_at
      assert_equal now, @privateer.reload.ccu_target_seen_at
      assert_nil @pioneer.reload.ccu_source_seen_at
      assert_nil @pioneer.ccu_target_seen_at
    end

    test "a ship keeps the date it was first seen" do
      first = Time.zone.parse("2026-01-01 12:00")
      @carrack.update!(ccu_target_seen_at: first)
      create(:hangar_pledge_item, kind: "ccu", name: "Upgrade - Cutlass Black to Carrack")

      CcuCatalogue.new.run

      assert_equal first, @carrack.reload.ccu_target_seen_at
    end
  end
end
