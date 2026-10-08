# frozen_string_literal: true

require "test_helper"

class InventoryPositionTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:inventory)
  end

  test "the slug is the address three endpoints already publish" do
    position = create(:inventory_position, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu)

    assert_equal "quantanium--commodity--scu", position.slug
  end

  # The name is parameterized, so these two identities generate one slug. Today
  # the loser is simply unreachable -- whichever `detect` hits first wins.
  test "a second position competing for the same slug gets a suffix" do
    create(:inventory_position, inventory: @inventory, name: "Med Pens", category: :consumable, unit: :units)
    second = create(:inventory_position, inventory: @inventory, name: "med-pens", category: :consumable, unit: :units)

    assert_equal "med-pens--consumable--units-2", second.slug
  end

  test "the same slug in another inventory is not a collision" do
    create(:inventory_position, inventory: @inventory, name: "Quantanium")
    other = create(:inventory_position, inventory: create(:inventory), name: "Quantanium")

    assert_equal "quantanium--commodity--scu", other.slug
  end

  # Unenforced until this table existed: nothing stopped two of the same triple.
  test "the identity is unique per inventory" do
    create(:inventory_position, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu)

    assert_raises ActiveRecord::RecordNotUnique do
      create(:inventory_position, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu)
    end
  end

  test "renaming files one version rather than one per entry" do
    position = create(:inventory_position, inventory: @inventory, name: "Quantanium")
    create_list(:inventory_item, 3, inventory: @inventory, inventory_position: position)

    assert_difference -> { position.versions.count }, 1 do
      position.update!(name: "Quantanium Ore")
    end

    assert_equal ["Quantanium", "Quantanium Ore"], position.versions.last.changeset["name"]
  end

  test "renaming moves the address with it" do
    position = create(:inventory_position, inventory: @inventory, name: "Quantanium")

    position.update!(name: "Quantanium Ore")

    assert_equal "quantanium-ore--commodity--scu", position.reload.slug
  end

  test "a name is required" do
    assert_predicate build(:inventory_position, inventory: @inventory, name: " "), :invalid?
  end

  # The entry's own identity is what decides its position while both still carry
  # name, category and unit -- an entry cannot be pointed at a position that
  # disagrees with it. That inverts once the columns are dropped.
  test "a position holding entries is not destroyed out from under them" do
    entry = create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, unit: :scu)
    position = entry.position

    refute position.destroy
    assert_predicate position.reload, :persisted?
  end

  test "destroying the inventory takes its positions with it" do
    create_list(:inventory_position, 2, inventory: @inventory)

    assert_difference "InventoryPosition.count", -2 do
      @inventory.destroy
    end
  end
end
