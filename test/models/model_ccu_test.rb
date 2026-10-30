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

  test "an admin override wins over what was seen" do
    blocked = build(:model, ccu_override: "none", ccu_on_sale: true, ccu_target_seen_at: 1.day.ago)
    allowed = build(:model, ccu_override: "allowed", created_at: 1.year.ago)

    assert_equal "none", blocked.ccu_target_status
    assert_equal "none", blocked.ccu_source_status
    assert_equal "sales_only", allowed.ccu_target_status
    assert_equal "known", allowed.ccu_source_status
  end
end
