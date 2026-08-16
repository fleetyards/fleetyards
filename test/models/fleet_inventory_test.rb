# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  managed_by  :uuid
#  name        :string           not null
#  slug        :string           not null
#  visibility  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  fleet_id    :uuid             not null
#
# Indexes
#
#  index_fleet_inventories_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_inventories_on_fleet_id_and_managed_by  (fleet_id,managed_by)
#  index_fleet_inventories_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (managed_by => users.id)
#
class FleetInventoryTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    @inventory = create(:fleet_inventory, fleet: @fleet, name: "Area 18 Locker")
  end

  test "generates a slug from the name" do
    assert_equal "area-18-locker", @inventory.slug
  end

  test "names are unique per fleet but not across fleets" do
    duplicate = build(:fleet_inventory, fleet: @fleet, name: "area 18 locker")

    assert_not duplicate.valid?

    other = build(:fleet_inventory, fleet: create(:fleet), name: "Area 18 Locker")

    assert_predicate other, :valid?
  end

  test "current_stock nets deposits against withdrawals" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Titanium", quantity: 20, unit: :scu)

    stock = @inventory.current_stock

    assert_equal 70, stock.find { |s| s.name == "Quantanium" }.net_quantity
    assert_equal 20, stock.find { |s| s.name == "Titanium" }.net_quantity
  end

  test "current_stock omits fully withdrawn entries" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu, entry_type: :withdrawal)

    assert_empty @inventory.current_stock
  end

  test "destroying the inventory destroys its ledger entries" do
    create_list(:fleet_inventory_item, 2, fleet_inventory: @inventory)

    assert_difference "FleetInventoryItem.count", -2 do
      @inventory.destroy
    end
  end

  test "ledger attributes credit entries to the acting user" do
    user = create(:user)

    assert_equal({added_by: user.id}, @inventory.ledger_attributes_for(user))
  end
end
