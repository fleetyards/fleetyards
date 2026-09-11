# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260911000000_backfill_inventory_positions.rb")

# The one data migration here with a test, deliberately. Its slug
# disambiguation is the part most likely to break a deploy -- the unique index
# turns a collision into a hard failure inside the pre-deploy hook -- and it
# carries its own copy of the derivation by convention, so the copy in
# `StockPosition` being tested says nothing about this one.
class BackfillInventoryPositionsTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:inventory)
  end

  # Entries arrive already pointed at a position now, so the state this migration
  # exists for is reached by running its own `down` first -- which is also what
  # makes calling this twice mean what a re-run means.
  def backfill
    BackfillInventoryPositions.new.down
    BackfillInventoryPositions.new.up
  end

  test "entries sharing an identity end up in one position" do
    deposit = create(:inventory_item, inventory: @inventory, name: "Quantanium",
      category: :commodity, unit: :scu, quantity: 100)
    withdrawal = create(:inventory_item, inventory: @inventory, name: "Quantanium",
      category: :commodity, unit: :scu, quantity: 30, entry_type: :withdrawal)

    backfill

    assert_equal deposit.reload.inventory_position_id, withdrawal.reload.inventory_position_id
    assert_equal "quantanium--commodity--scu", deposit.position.slug
  end

  test "a differing unit is a position of its own" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :other, unit: :units, quantity: 5)

    backfill

    assert_equal 2, @inventory.positions.count
  end

  test "the same identity in another inventory is a position of its own" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)
    other = create(:inventory)
    create(:inventory_item, inventory: other, name: "Quantanium", category: :commodity, unit: :scu, quantity: 1)

    backfill

    assert_equal 1, @inventory.positions.count
    assert_equal 1, other.positions.count
  end

  # Two identities, one address. The unique index would stop the backfill dead
  # here, and today the loser is simply unreachable.
  test "two names competing for one slug both stay addressable" do
    create(:inventory_item, inventory: @inventory, name: "Med Pens", category: :consumable, unit: :units, quantity: 5)
    create(:inventory_item, inventory: @inventory, name: "med-pens", category: :consumable, unit: :units, quantity: 7)

    backfill

    slugs = @inventory.positions.order(:slug).pluck(:slug)

    assert_equal ["med-pens--consumable--units", "med-pens--consumable--units-2"], slugs
  end

  # Which of the two keeps the clean slug is arbitrary, but it must not vary
  # between a re-run or an environment.
  test "the collision resolves the same way twice" do
    create(:inventory_item, inventory: @inventory, name: "Med Pens", category: :consumable, unit: :units, quantity: 5)
    create(:inventory_item, inventory: @inventory, name: "med-pens", category: :consumable, unit: :units, quantity: 7)

    backfill
    first = @inventory.positions.order(:name).pluck(:name, :slug)

    backfill
    assert_equal first, @inventory.positions.order(:name).pluck(:name, :slug)
  end

  test "fleet entries are backfilled too" do
    inventory = create(:fleet_inventory)
    entry = create(:fleet_inventory_item, fleet_inventory: inventory, name: "Titanium",
      category: :commodity, unit: :scu, quantity: 9)

    backfill

    assert_equal "titanium--commodity--scu", entry.reload.position.slug
    assert_equal inventory, entry.position.inventory
  end

  test "nothing is left unpointed" do
    3.times do |n|
      create(:inventory_item, inventory: @inventory, name: "Ore #{n}", category: :commodity, unit: :scu, quantity: 1)
    end

    backfill

    assert_empty InventoryItem.where(inventory_position_id: nil)
  end

  # A retried pre-deploy hook runs it again.
  test "a re-run adds nothing" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium",
      category: :commodity, unit: :scu, quantity: 100)
    backfill

    assert_no_difference "InventoryPosition.count" do
      BackfillInventoryPositions.new.up
    end
  end

  test "down unpoints the entries and clears the positions" do
    entry = create(:inventory_item, inventory: @inventory, name: "Quantanium",
      category: :commodity, unit: :scu, quantity: 100)
    backfill

    BackfillInventoryPositions.new.down

    assert_nil entry.reload.inventory_position_id
    assert_empty InventoryPosition.all
  end
end
