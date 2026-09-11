# frozen_string_literal: true

require "test_helper"

# Every way an entry comes into existence has to leave it pointing at a
# position, which is why the resolution is on the model rather than in the five
# call sites that create one.
class InventoryEntryPositionTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:inventory)
    @identity = {name: "Quantanium", category: :commodity, unit: :scu}
  end

  test "a new entry creates the position it belongs to" do
    assert_difference "InventoryPosition.count", 1 do
      entry = create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))

      assert_equal "Quantanium", entry.position.name
      assert_equal @inventory, entry.position.inventory
    end
  end

  test "a second entry of the same identity joins the position" do
    first = create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))

    assert_no_difference "InventoryPosition.count" do
      second = create(:inventory_item, :withdrawal, @identity.merge(inventory: @inventory, quantity: 30))

      assert_equal first.position, second.position
    end
  end

  test "a different unit is a different position" do
    create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))

    assert_difference "InventoryPosition.count", 1 do
      create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :other, unit: :units, quantity: 5)
    end
  end

  test "the same identity in another inventory is its own position" do
    create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))

    assert_difference "InventoryPosition.count", 1 do
      create(:inventory_item, @identity.merge(inventory: create(:inventory), quantity: 100))
    end
  end

  # `before_save`, not `before_validation` -- otherwise a rejected deposit
  # leaves a position nobody asked for.
  test "a rejected entry leaves no position behind" do
    assert_no_difference "InventoryPosition.count" do
      entry = build(:inventory_item, @identity.merge(inventory: @inventory, quantity: 0))

      refute entry.save
    end
  end

  test "an entry alone in its position takes the position with it when renamed" do
    entry = create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))
    was = entry.position

    entry.update!(name: "Quantanium Ore")

    refute_equal was, entry.reload.position
    assert_equal "Quantanium Ore", entry.position.name
  end

  test "a notes-only update does not re-resolve the position" do
    entry = create(:inventory_item, @identity.merge(inventory: @inventory, quantity: 100))
    was = entry.position

    assert_no_difference "InventoryPosition.count" do
      entry.update!(notes: "hold 2")
    end

    assert_equal was, entry.reload.position
  end

  # A position has to be able to represent an entry that predates the pairing
  # rule, or the backfill would fail on exactly the rows it exists for.
  test "an entry with a grandfathered unit and category still gets a position" do
    legacy = create(:inventory_item, inventory: @inventory, name: "Odd", category: :other, unit: :scu, quantity: 1)
    legacy.update_columns(category: InventoryLedgerEntry::CATEGORIES[:component])

    assert_difference "InventoryPosition.count", 1 do
      legacy.reload.update!(quantity: 2, name: "Odd Two")
    end
  end

  # The other table, reached through the aliases named for it.
  test "a fleet entry resolves a fleet position" do
    inventory = create(:fleet_inventory)

    entry = create(:fleet_inventory_item, name: "Quantanium", category: :commodity, unit: :scu,
      quantity: 100, fleet_inventory: inventory)

    assert_instance_of FleetInventoryPosition, entry.position
    assert_equal entry.fleet_inventory_position, entry.position
    assert_equal inventory, entry.position.inventory
  end

  test "two fleet entries of one identity share a position" do
    inventory = create(:fleet_inventory)
    base = {fleet_inventory: inventory, name: "Quantanium", category: :commodity, unit: :scu}
    first = create(:fleet_inventory_item, base.merge(quantity: 100))

    assert_no_difference "FleetInventoryPosition.count" do
      assert_equal first.position, create(:fleet_inventory_item, :withdrawal, base.merge(quantity: 30)).position
    end
  end

  test "the CSV import points every row at a position" do
    csv = Tempfile.new(["import", ".csv"])
    csv.write("name,category,quantity,unit\nQuantanium,commodity,10,scu\nQuantanium,commodity,5,scu\nTitanium,commodity,7,scu\n")
    csv.rewind
    file = Rack::Test::UploadedFile.new(csv.path, "text/csv")

    assert_difference "InventoryPosition.count", 2 do
      InventoryItemCsvImporter.new(@inventory, file, @inventory.holder).call
    end

    assert_empty @inventory.inventory_items.where(inventory_position_id: nil)
  end
end
