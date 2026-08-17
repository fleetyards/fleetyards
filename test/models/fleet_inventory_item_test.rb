# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_inventory_items
#
#  id                 :uuid             not null, primary key
#  added_by           :uuid
#  category           :integer          default(0), not null
#  entry_type         :integer          default(0), not null
#  item_type          :string
#  name               :string           not null
#  notes              :text
#  quality            :integer          default(0)
#  quantity           :decimal(15, 2)   default(0.0), not null
#  unit               :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  fleet_inventory_id :uuid             not null
#  item_id            :uuid
#  member_id          :uuid
#
# Indexes
#
#  index_fleet_inventory_items_on_fleet_inventory_id  (fleet_inventory_id)
#  index_fleet_inventory_items_on_member_id           (member_id)
#
# Foreign Keys
#
#  fk_rails_...  (added_by => users.id)
#  fk_rails_...  (fleet_inventory_id => fleet_inventories.id)
#  fk_rails_...  (member_id => users.id)
#
class FleetInventoryItemTest < ActiveSupport::TestCase
  setup do
    @inventory = create(:fleet_inventory)
  end

  test "requires a positive quantity" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory, quantity: 0)

    assert_not item.valid?
  end

  test "rejects a withdrawal exceeding current stock" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:fleet_inventory_item, :withdrawal,
      fleet_inventory: @inventory, name: "Quantanium", quantity: 11, unit: :scu)

    assert_not withdrawal.valid?
    assert_includes withdrawal.errors[:quantity].join, "exceeds current stock"
  end

  test "allows a withdrawal within current stock" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:fleet_inventory_item, :withdrawal,
      fleet_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    assert_predicate withdrawal, :valid?
  end

  test "stock is tracked per unit" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:fleet_inventory_item, :withdrawal,
      fleet_inventory: @inventory, name: "Quantanium", quantity: 1, unit: :units)

    assert_not withdrawal.valid?
  end

  test "stock is tracked per inventory" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 10, unit: :scu)

    withdrawal = build(:fleet_inventory_item, :withdrawal,
      fleet_inventory: create(:fleet_inventory), name: "Quantanium", quantity: 1, unit: :scu)

    assert_not withdrawal.valid?
  end

  test "takes its name from a referenced component" do
    component = create(:component, name: "FR-66 Shield Generator")

    item = create(:fleet_inventory_item, fleet_inventory: @inventory, name: nil, item: component)

    assert_equal "FR-66 Shield Generator", item.name
  end

  test "rejects an item type outside the allowed list" do
    fleet = create(:fleet)

    item = build(:fleet_inventory_item, fleet_inventory: @inventory, item_type: "Fleet", item_id: fleet.id)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_type
  end

  test "rejects an item id without an item type" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory, item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_type
  end

  test "accepts a reference to a commodity" do
    commodity = create(:commodity, name: "Gold")

    item = build(:fleet_inventory_item, fleet_inventory: @inventory, name: nil,
      category: :commodity, unit: :scu, item: commodity)

    assert_predicate item, :valid?
    assert_equal "Gold", item.name
  end

  # One table covers weapons, attachments and magazines, so all three ledger
  # categories reference Equipment rather than a catalogue each.
  test "accepts a reference to equipment" do
    equipment = create(:equipment, name: "P4-AR Rifle")

    item = build(:fleet_inventory_item, fleet_inventory: @inventory, name: nil,
      category: :weapon, unit: :units, item: equipment)

    assert_predicate item, :valid?
    assert_equal "P4-AR Rifle", item.name
  end

  test "accepts equipment on an ammunition entry" do
    magazine = create(:equipment, :magazine, name: "P4-AR Magazine")

    item = build(:fleet_inventory_item, fleet_inventory: @inventory, name: nil,
      category: :ammunition, unit: :units, item: magazine)

    assert_predicate item, :valid?
  end

  test "rejects a reference to equipment that does not exist" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory,
      item_type: "Equipment", item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_id
  end

  test "rejects a reference to a commodity that does not exist" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory,
      item_type: "Commodity", item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_id
  end

  test "rejects a reference to a component that does not exist" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory,
      item_type: "Component", item_id: SecureRandom.uuid)

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :item_id
  end

  test "rejects SCU for a component entry" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory, category: :component, unit: :scu)

    assert_not item.valid?
    assert_includes item.errors[:unit].join, "must be units for component entries"
  end

  test "rejects units for a commodity entry" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory, category: :commodity, unit: :units)

    assert_not item.valid?
  end

  test "allows either unit for an other entry" do
    InventoryLedgerEntry::UNITS.each_key do |unit|
      item = build(:fleet_inventory_item, fleet_inventory: @inventory, category: :other, unit: unit)

      assert_predicate item, :valid?
    end
  end

  test "leaves a stored mismatch alone until unit or category is touched" do
    item = build(:fleet_inventory_item, fleet_inventory: @inventory, category: :component, unit: :scu)
    item.save!(validate: false)

    assert item.update(notes: "still fine")
    assert item.update(category: :commodity), "commodity accepts the stored scu unit"

    item.update_column(:category, InventoryLedgerEntry::CATEGORIES[:component])

    assert_not item.reload.update(category: :weapon)
  end

  test "notifies the members who manage the inventory" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    inventory = create(:fleet_inventory, fleet: fleet)

    assert_difference "Notification.where(user: admin).count", 1 do
      create(:fleet_inventory_item, fleet_inventory: inventory)
    end
  end

  test "notifies the inventory manager on top of the fleet management" do
    manager = create(:user)
    fleet = create(:fleet, admins: [create(:user)])
    inventory = create(:fleet_inventory, fleet: fleet, manager: manager)

    assert_difference "Notification.where(user: manager).count", 1 do
      create(:fleet_inventory_item, fleet_inventory: inventory)
    end
  end

  test "leaves plain members without a notification" do
    member = create(:user)
    fleet = create(:fleet, admins: [create(:user)], members: [member])
    inventory = create(:fleet_inventory, fleet: fleet)

    assert_no_difference "Notification.where(user: member).count" do
      create(:fleet_inventory_item, fleet_inventory: inventory)
    end
  end
end
