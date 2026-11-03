# frozen_string_literal: true

require "test_helper"

class ModelCcuTest < ActiveSupport::TestCase
  test "a ship an upgrade was ever seen into is upgradable, on sale or only in sales" do
    on_sale = build(:model, ccu_on_sale: true, ccu_target_seen_at: 1.day.ago)
    seen = build(:model, ccu_target_seen_at: 1.year.ago, created_at: 2.years.ago)

    assert_equal "on_sale", on_sale.ccu_target_status
    assert_equal "sales_only", seen.ccu_target_status
    assert_equal "known", seen.ccu_source_status
  end

  test "a ship nobody saw an upgrade for is unknown while new, then has none" do
    fresh = build(:model, created_at: 1.week.ago)
    old = build(:model, created_at: 1.year.ago)

    assert_equal "unknown", fresh.ccu_target_status
    assert_equal "unknown", fresh.ccu_source_status
    assert_equal "none", old.ccu_target_status
    assert_not old.ccu_out_of?
  end

  test "a ship the store does not sell takes no upgrades, whatever was seen" do
    ingame = build(:model, ingame_only: true, ccu_on_sale: true, ccu_override: "allowed")
    npc = build(:model, player_ownable: false, ccu_target_seen_at: 1.day.ago)

    assert_equal "none", ingame.ccu_target_status
    assert_equal "none", ingame.ccu_source_status
    assert_equal "none", npc.ccu_target_status
    assert_equal "none", npc.ccu_source_status
  end

  test "an admin override wins over what was seen" do
    blocked = build(:model, ccu_override: "none", ccu_on_sale: true, ccu_target_seen_at: 1.day.ago)
    allowed = build(:model, ccu_override: "allowed", created_at: 1.year.ago)

    assert_equal "none", blocked.ccu_target_status
    assert_equal "none", blocked.ccu_source_status
    assert_equal "sales_only", allowed.ccu_target_status
    assert_equal "known", allowed.ccu_source_status
  end

  test "the ccu_target scope holds the ships an upgrade can lead into" do
    ships = {
      on_sale: create(:model, ccu_on_sale: true),
      seen: create(:model, ccu_target_seen_at: 1.year.ago, created_at: 2.years.ago),
      fresh: create(:model, created_at: 1.week.ago),
      old: create(:model, created_at: 1.year.ago),
      blocked: create(:model, ccu_override: "none", ccu_on_sale: true),
      allowed: create(:model, ccu_override: "allowed", created_at: 1.year.ago),
      ingame: create(:model, ingame_only: true, ccu_on_sale: true),
      npc: create(:model, player_ownable: false, ccu_on_sale: true)
    }

    scoped = Model.where(id: ships.values).ccu_target.to_a

    assert_equal ships.values.select(&:ccu_into?).map(&:id).sort, scoped.map(&:id).sort
    assert_equal %i[allowed fresh on_sale seen], ships.select { |_, ship| scoped.include?(ship) }.keys.sort
  end
end
