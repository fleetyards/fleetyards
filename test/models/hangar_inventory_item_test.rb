# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: hangar_inventory_items
#
#  id                  :uuid             not null, primary key
#  category            :integer          default("commodity"), not null
#  entry_type          :integer          default("deposit"), not null
#  item_type           :string
#  name                :string           not null
#  notes               :text
#  quality             :integer          default(0)
#  quantity            :decimal(15, 2)   default(0.0), not null
#  unit                :integer          default("scu"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  hangar_inventory_id :uuid             not null
#  item_id             :uuid
#
# Indexes
#
#  index_hangar_inventory_items_on_hangar_inventory_id  (hangar_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (hangar_inventory_id => hangar_inventories.id)
#
class HangarInventoryItemTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:hangar_inventory)
  end

  test "requires a positive quantity" do
    item = build(:hangar_inventory_item, hangar_inventory: @inventory, quantity: 0)

    assert_not item.valid?
  end

  test "rejects a withdrawal exceeding current stock" do
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:hangar_inventory_item, :withdrawal,
      hangar_inventory: @inventory, name: "Quantanium", quantity: 11, unit: :scu)

    assert_not withdrawal.valid?
    assert_includes withdrawal.errors[:quantity].join, "exceeds current stock"
  end

  test "allows a withdrawal within current stock" do
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:hangar_inventory_item, :withdrawal,
      hangar_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    assert_predicate withdrawal, :valid?
  end

  test "stock is tracked per unit" do
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:hangar_inventory_item, :withdrawal,
      hangar_inventory: @inventory, name: "Quantanium", quantity: 1, unit: :units)

    assert_not withdrawal.valid?
  end

  test "does not create notifications" do
    assert_no_difference "Notification.count" do
      create(:hangar_inventory_item, hangar_inventory: @inventory)
    end
  end
end
