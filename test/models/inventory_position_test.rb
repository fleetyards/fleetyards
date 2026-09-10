# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: inventory_positions
#
#  id           :uuid             not null, primary key
#  category     :integer          default(0), not null
#  name         :string           not null
#  slug         :string           not null
#  unit         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inventory_id :uuid             not null
#
# Indexes
#
#  index_inventory_positions_on_inventory_and_identity  (inventory_id,name,category,unit) UNIQUE
#  index_inventory_positions_on_inventory_and_slug      (inventory_id,slug) UNIQUE
#  index_inventory_positions_on_inventory_id            (inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_id => inventories.id) ON DELETE => cascade
#
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

  test "a unit the category is not measured in is refused" do
    position = build(:inventory_position, inventory: @inventory, category: :component, unit: :scu)

    assert_predicate position, :invalid?
    assert_includes position.errors.full_messages.to_s, "must be units for component entries"
  end

  test "a name is required" do
    assert_predicate build(:inventory_position, inventory: @inventory, name: " "), :invalid?
  end

  test "a position holding entries is not destroyed out from under them" do
    position = create(:inventory_position, inventory: @inventory)
    create(:inventory_item, inventory: @inventory, inventory_position: position)

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
