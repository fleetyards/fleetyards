# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: inventory_items
#
#  id           :uuid             not null, primary key
#  category     :integer          default(0), not null
#  entry_type   :integer          default(0), not null
#  item_type    :string
#  name         :string           not null
#  notes        :text
#  quality      :integer          default(0)
#  quantity     :decimal(15, 2)   default(0.0), not null
#  unit         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inventory_id :uuid             not null
#  item_id      :uuid
#
# Indexes
#
#  index_inventory_items_on_inventory_id  (inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_id => inventories.id)
#
class HangarInventoryItemTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:inventory)
  end

  test "requires a positive quantity" do
    item = build(:inventory_item, inventory: @inventory, quantity: 0)

    assert_not item.valid?
  end

  test "rejects a withdrawal exceeding current stock" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:inventory_item, :withdrawal,
      inventory: @inventory, name: "Quantanium", quantity: 11, unit: :scu)

    assert_not withdrawal.valid?
    assert_includes withdrawal.errors[:quantity].join, "exceeds current stock"
  end

  test "allows a withdrawal within current stock" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:inventory_item, :withdrawal,
      inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    assert_predicate withdrawal, :valid?
  end

  test "stock is tracked per unit" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:inventory_item, :withdrawal,
      inventory: @inventory, name: "Quantanium", quantity: 1, unit: :units)

    assert_not withdrawal.valid?
  end

  test "takes its name from a referenced component" do
    component = create(:component, name: "FR-66 Shield Generator")

    item = create(:inventory_item, inventory: @inventory, name: nil, item: component)

    assert_equal "FR-66 Shield Generator", item.name
  end

  test "rejects an item type outside the allowed list" do
    fleet = create(:fleet)

    item = build(:inventory_item, inventory: @inventory, item_type: "Fleet", item_id: fleet.id)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_type
  end

  test "rejects an item id without an item type" do
    item = build(:inventory_item, inventory: @inventory, item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_type
  end

  test "rejects a reference to a component that does not exist" do
    item = build(:inventory_item, inventory: @inventory,
      item_type: "Component", item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_id
  end

  test "rejects SCU for a component entry" do
    item = build(:inventory_item, inventory: @inventory, category: :component, unit: :scu)

    assert_not item.valid?
    assert_includes item.errors[:unit].join, "must be units for component entries"
  end

  test "rejects units for a commodity entry" do
    item = build(:inventory_item, inventory: @inventory, category: :commodity, unit: :units)

    assert_not item.valid?
  end

  test "allows either unit for an other entry" do
    InventoryLedgerEntry::UNITS.each_key do |unit|
      item = build(:inventory_item, inventory: @inventory, category: :other, unit: unit)

      assert_predicate item, :valid?
    end
  end

  test "leaves a stored mismatch alone until unit or category is touched" do
    item = build(:inventory_item, inventory: @inventory, category: :component, unit: :scu)
    item.save!(validate: false)

    assert item.update(notes: "still fine")
    assert item.update(category: :commodity), "commodity accepts the stored scu unit"

    item.update_column(:category, InventoryLedgerEntry::CATEGORIES[:component])

    assert_not item.reload.update(category: :weapon)
  end

  test "does not create notifications" do
    assert_no_difference "Notification.count" do
      create(:inventory_item, inventory: @inventory)
    end
  end
end
