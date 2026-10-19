# frozen_string_literal: true

require "test_helper"

# A crafted part: the recipe it was made from and the grade of material in
# each of the recipe's graded slots.
class InventoryItemCraftedTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @inventory = create(:inventory, holder: @user)
    @component = create(:component, name: "Bulwark")
    @blueprint = create(:blueprint, craftable: @component)

    frame = create(:blueprint_cost_slot, build: @blueprint.build, position: 1)
    create(:blueprint_cost_modifier, slot: frame)
    capacitor = create(:blueprint_cost_slot, build: @blueprint.build, position: 2)
    create(:blueprint_cost_modifier, slot: capacitor)
    # Takes any grade and moves nothing, so nobody is asked for one.
    create(:blueprint_cost_slot, build: @blueprint.build, position: 3)

    @blueprint.reload
  end

  test "records the recipe and the grade in each graded slot" do
    entry = crafted(qualities: {1 => 750, 2 => 500})

    assert_predicate entry, :valid?, entry.errors.full_messages.to_sentence
    assert_equal({"1" => 750, "2" => 500}, entry.crafted_qualities)
  end

  test "asks for a grade in every slot that moves a stat" do
    entry = crafted(qualities: {1 => 750})

    assert_not entry.valid?
    assert entry.errors[:crafted_qualities].any?
  end

  test "does not take a grade for a slot that moves nothing" do
    entry = crafted(qualities: {1 => 750, 2 => 500, 3 => 100})

    assert_not entry.valid?
  end

  test "keeps every grade within 0 to 1000" do
    assert_not crafted(qualities: {1 => 1001, 2 => 500}).valid?
    assert_not crafted(qualities: {1 => "high", 2 => 500}).valid?
  end

  test "takes only a recipe that makes the item" do
    other = create(:blueprint, craftable: create(:component))

    entry = crafted(qualities: {1 => 750, 2 => 500}, blueprint: other)

    assert_not entry.valid?
    assert entry.errors[:crafted_blueprint_id].any?
  end

  test "takes a recipe only for a part, not for goods typed by hand" do
    entry = build(:inventory_item, :component, inventory: @inventory, name: "Bulwark",
      crafted_blueprint: @blueprint, crafted_qualities: {1 => 750, 2 => 500})

    assert_not entry.valid?
    assert entry.errors[:crafted_blueprint_id].any?
  end

  test "does not take grades without a recipe" do
    entry = build(:inventory_item, :component, inventory: @inventory,
      item: @component, crafted_qualities: {1 => 750})

    assert_not entry.valid?
    assert entry.errors[:crafted_blueprint_id].any?
  end

  # Worth depends on what went into it, so a crafted lot is held apart from
  # the same part bought, and from one crafted with other material.
  test "holds crafted lots apart in the stock" do
    create(:inventory_item, :component, inventory: @inventory, item: @component, name: "Bulwark",
      quantity: 2, quality: nil)
    crafted(qualities: {1 => 750, 2 => 500}, quantity: 1).save!
    crafted(qualities: {1 => 750, 2 => 500}, quantity: 1).save!
    crafted(qualities: {1 => 200, 2 => 900}, quantity: 3).save!

    rows = @inventory.reload.current_stock.to_a

    assert_equal 1, rows.map(&:position_id).uniq.size, "still one position"
    assert_equal [2, 2, 3], rows.map { |row| row.net_quantity.to_i }.sort
    assert_equal 2, rows.count(&:crafted_blueprint_id)
  end

  test "a crafted lot moves with its recipe and grades" do
    Flipper.enable_actor(:hangar_inventories, @user)
    destination = create(:inventory, holder: @user)
    crafted(qualities: {1 => 750, 2 => 500}, quantity: 2).save!
    position = @inventory.positions.first

    builder = Inventories::TransferBuilder.new(
      source: @inventory, actor: @user, destination:,
      lines: [{position_id: position.id, quantity: 2}]
    )

    assert builder.call, builder.errors.full_messages.to_sentence

    arrived = destination.reload.inventory_items.sole

    assert_equal @blueprint.id, arrived.crafted_blueprint_id
    assert_equal({"1" => 750, "2" => 500}, arrived.crafted_qualities)
  end

  # Least valuable first: plain stock leaves before a crafted lot does.
  test "a transfer ships plain stock ahead of a crafted lot" do
    Flipper.enable_actor(:hangar_inventories, @user)
    destination = create(:inventory, holder: @user)
    crafted(qualities: {1 => 750, 2 => 500}, quantity: 1).save!
    create(:inventory_item, :component, inventory: @inventory, item: @component, name: "Bulwark",
      quantity: 1, quality: nil)
    position = @inventory.positions.first

    builder = Inventories::TransferBuilder.new(
      source: @inventory, actor: @user, destination:,
      lines: [{position_id: position.id, quantity: 1}]
    )

    assert builder.call, builder.errors.full_messages.to_sentence
    assert_nil destination.reload.inventory_items.sole.crafted_blueprint_id
  end

  private def crafted(qualities:, blueprint: @blueprint, quantity: 1)
    build(:inventory_item, :component, inventory: @inventory, item: @component, name: "Bulwark",
      quantity:, quality: nil, crafted_blueprint: blueprint, crafted_qualities: qualities)
  end
end
