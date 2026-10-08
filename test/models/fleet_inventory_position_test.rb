# frozen_string_literal: true

require "test_helper"

# The behaviour lives in `StockPosition`, so these cover the part that differs:
# the association is named for the fleet table and reached through the aliases.
class FleetInventoryPositionTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:fleet_inventory)
  end

  test "the inventory is reachable under both names" do
    position = create(:fleet_inventory_position, fleet_inventory: @inventory)

    assert_equal @inventory, position.fleet_inventory
    assert_equal @inventory, position.inventory
    assert_equal @inventory.id, position.inventory_id
  end

  test "the slug is the published address" do
    position = create(:fleet_inventory_position, fleet_inventory: @inventory, name: "Quantanium",
      category: :commodity, unit: :scu)

    assert_equal "quantanium--commodity--scu", position.slug
  end

  test "the identity is unique per inventory" do
    create(:fleet_inventory_position, fleet_inventory: @inventory, name: "Quantanium")

    assert_raises ActiveRecord::RecordNotUnique do
      create(:fleet_inventory_position, fleet_inventory: @inventory, name: "Quantanium")
    end
  end

  test "renaming files one version" do
    position = create(:fleet_inventory_position, fleet_inventory: @inventory, name: "Quantanium")

    assert_difference -> { position.versions.count }, 1 do
      position.update!(name: "Quantanium Ore")
    end
  end

  test "the inventory reaches its positions under both names" do
    create_list(:fleet_inventory_position, 2, fleet_inventory: @inventory)

    assert_equal 2, @inventory.fleet_inventory_positions.count
    assert_equal 2, @inventory.positions.count
  end
end
