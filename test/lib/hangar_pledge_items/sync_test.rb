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

  test "keeps ship parts as ship components, linked to the part they are" do
    cooler = create(:component, name: "BriskAir IC-20")
    repeater = create(:component, name: "CF-117 Bulldog Repeater")
    create(:component, name: "CF-117 Bulldog \"Hazard-Zone\" Repeater")
    items = [
      {id: "2001", type: "component", name: "BriskAir IC-20"},
      {id: "2001", type: "component", name: "CF-117 Bulldog (S1)"},
      {id: "2001", type: "component", name: "J-Span Cryo-Star Cooler"}
    ]

    result = HangarPledgeItems::Sync.new(@user, items, kinds: ["ship_component"]).run

    stored = @user.hangar_pledge_items.ship_components.index_by(&:name)
    assert_equal stored.values.map(&:id).sort, result["ship_component"].sort
    assert_equal cooler, stored["BriskAir IC-20"].catalogue_component
    assert_equal repeater, stored["CF-117 Bulldog (S1)"].catalogue_component
    assert_nil stored["J-Span Cryo-Star Cooler"].catalogue_component
  end

  test "picks the size RSI names among parts of one name, the smallest otherwise, and never a retired one" do
    create(:component, name: "M9A Cannon", size: "12", with_build: false)
    small = create(:component, name: "M9A Cannon", size: "7")
    large = create(:component, name: "M9A Cannon", size: "8")
    catalogue = HangarPledgeItems::Sync::ComponentCatalogue.new

    assert_equal small.id, catalogue.find("M9A Cannon")
    assert_equal large.id, catalogue.find("M9A Cannon (S8)")
    # The size-12 cannon is retired: the smallest current one stands in.
    assert_equal small.id, catalogue.find("M9A Cannon (S12)")
  end

  test "matches a flight blade, but no ship internal" do
    blade = create(:component, name: "Agility Blade", category: "controller", component_type: "FlightController")
    create(:component, name: "Cargo Door", category: "doors")
    catalogue = HangarPledgeItems::Sync::ComponentCatalogue.new

    assert_equal blade.id, catalogue.find("Agility Blade")
    assert_nil catalogue.find("Cargo Door")
  end

  # Modules are fitted to a ship by the hangar sync, whether it knows them or not.
  test "leaves ship modules to the hangar sync" do
    items = [
      {id: "2002", type: "component", name: "Aurora Mk II Cargo Module"},
      {id: "2002", type: "component", name: "Mystery Ship - Science Module"}
    ]

    assert_equal [nil, nil], HangarPledgeItems::Sync.kinds_for(items)
  end

  test "links FPS gear to the catalogue item it is" do
    rifle = create(:equipment, name: "P4-AR Rifle")
    items = [{id: "2003", type: "equipment", name: "P4-AR Rifle"}]

    HangarPledgeItems::Sync.new(@user, items, kinds: ["equipment"]).run

    assert_equal rifle, @user.hangar_pledge_items.equipment.sole.catalogue_equipment
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
