# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::SyncTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @paint = create(:model_paint, model: create(:model, name: "Nomad"), name: "Ice Break")
  end

  test "links each synced paint to the catalogue paint it is" do
    items = [{id: "1001", type: "skin", name: "Nomad IceBreak Livery"}]

    HangarPledgeItems::Sync.new(@user, items, kinds: ["paint"]).run

    item = @user.hangar_pledge_items.paints.sole
    assert_equal [@paint], item.model_paints.to_a
  end

  test "stores duplicate CCUs with their pledge values and removes absent ones" do
    old = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Old CCU")
    item = {id: "1002", type: "ccu", name: "Upgrade - Aurora To Cutter", pledge_value: 10, pledge_item_count: 2, meltable: true}
    result = HangarPledgeItems::Sync.new(@user, [item, item], kinds: ["ccu"]).run
    ccu = @user.hangar_pledge_items.upgrades.sole
    assert_equal [ccu.id], result["ccu"]
    assert_equal 2, ccu.quantity
    assert_equal 10, ccu.melt_value
    assert_not HangarPledgeItem.exists?(old.id)
    HangarPledgeItems::Sync.new(@user, [], kinds: ["ccu"], keep_unlisted: true).run
    assert ccu.reload
  end

  test "remembers the RSI hangar page a CCU was read from" do
    item = {id: "1003", type: "ccu", name: "Upgrade - Aurora To Cutter", page: 4}

    HangarPledgeItems::Sync.new(@user, [item], kinds: ["ccu"]).run

    assert_equal 4, @user.hangar_pledge_items.upgrades.sole.rsi_page
  end

  test "syncs a CCU-only hangar without attempting vehicle upgrades and preserves skipped CCUs" do
    input = [{id: "1002", type: "ccu", name: "Upgrade - Aurora To Cutter"}]
    import = Imports::HangarSync.create!(user: @user, input:, sync_ccus: true)
    result = HangarSync.new(input).run_with_import(import)
    assert_equal "synced", result[:outcome]
    assert_equal @user.hangar_pledge_items.upgrades.ids, result[:synced_ccus]
    assert_empty result[:missing_upgrades]
    import = Imports::HangarSync.create!(user: @user, input:, sync_ccus: false)
    result = HangarSync.new(input).run_with_import(import)
    assert_equal "only_skipped_items", result[:outcome]
    assert_equal 1, @user.hangar_pledge_items.upgrades.count
  end
end
