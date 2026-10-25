# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261025030000_refile_worn_gear_tools_and_containers.rb")

class RefileWornGearToolsAndContainersTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:inventory)
    @helmet = create(:equipment, :armor, name: "Morningstar Helmet", slot: :helmet)
  end

  def deposit(name, category:, item: nil, inventory: @inventory, quantity: 2)
    create(:inventory_item, inventory:, name:, category:, unit: :units, quantity:,
      item_type: item&.class&.name, item_id: item&.id)
  end

  def refile
    RefileWornGearToolsAndContainers.new.up
  end

  test "moves a position holding one piece of armour to the armour category" do
    entry = deposit("Morningstar Helmet", category: :equipment, item: @helmet)

    refile

    assert_equal "armor", entry.reload.category
    assert_equal "armor", entry.inventory_position.category
    assert_match(/--armor--/, entry.inventory_position.slug)
  end

  test "lets a withdrawal picked from the catalogue draw on stock recorded before" do
    deposit("Morningstar Helmet", category: :equipment, item: @helmet)

    refile

    withdrawal = @inventory.inventory_items.build(name: "Morningstar Helmet", category: :armor, unit: :units,
      quantity: 1, entry_type: :withdrawal, item: @helmet)

    assert withdrawal.valid?, withdrawal.errors.full_messages.to_sentence
  end

  test "merges into the position the new category already holds" do
    old = deposit("Morningstar Helmet", category: :equipment, item: @helmet)
    new = deposit("Morningstar Helmet", category: :armor, item: @helmet)

    refile

    assert_equal new.inventory_position_id, old.reload.inventory_position_id
    assert_equal 1, @inventory.inventory_positions.where(name: "Morningstar Helmet").count
  end

  test "files a gadget the game still calls a weapon as a tool" do
    multitool = create(:equipment, name: "Pyro RYT Multi-Tool", item_type: "multitool", sub_type: "Gadget", weapon_class: nil)
    entry = deposit("Pyro RYT Multi-Tool", category: :weapon, item: multitool)

    refile

    assert_equal "tool", entry.reload.category
  end

  test "leaves a weapon, a line typed by hand and a mixed position where they are" do
    rifle = deposit("P4-AR Rifle", category: :weapon, item: create(:equipment, name: "P4-AR Rifle"))
    typed = deposit("Old Helmet", category: :equipment)
    linked = deposit("Mixed Helmet", category: :equipment, item: @helmet)
    deposit("Mixed Helmet", category: :equipment)

    refile

    assert_equal "weapon", rifle.reload.category
    assert_equal "equipment", typed.reload.category
    assert_equal "equipment", linked.reload.category
  end

  test "moves fleet stock the same way" do
    entry = create(:fleet_inventory_item, name: "Morningstar Helmet", category: :equipment, unit: :units,
      quantity: 1, item_type: "Equipment", item_id: @helmet.id)

    refile

    assert_equal "armor", entry.reload.category
    assert_equal "armor", entry.fleet_inventory_position.category
  end

  test "moves a contract item asking for a piece of armour" do
    item = create(:fleet_contract_item, name: "Morningstar Helmet", category: :equipment, unit: :units,
      quantity: 1, item_type: "Equipment", item_id: @helmet.id)

    refile

    assert_equal "armor", item.reload.category
  end
end
