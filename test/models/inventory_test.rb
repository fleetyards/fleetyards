# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  holder_type :string           not null
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  holder_id   :uuid             not null
#
# Indexes
#
#  index_inventories_on_holder_and_lower_name               (holder_type, holder_id, lower((name)::text)) UNIQUE
#  index_inventories_on_holder_type_and_holder_id           (holder_type,holder_id)
#  index_inventories_on_holder_type_and_holder_id_and_slug  (holder_type,holder_id,slug) UNIQUE
#
class InventoryTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @inventory = create(:inventory, holder: @user, name: "Area 18 Locker")
  end

  test "generates a slug from the name" do
    assert_equal "area-18-locker", @inventory.slug
  end

  test "names are unique per user but not across users" do
    duplicate = build(:inventory, holder: @user, name: "area 18 locker")

    assert_not duplicate.valid?

    other = build(:inventory, holder: create(:user), name: "Area 18 Locker")

    assert_predicate other, :valid?
  end

  test "current_stock nets deposits against withdrawals" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:inventory_item, inventory: @inventory, name: "Titanium", quantity: 20, unit: :scu)

    stock = @inventory.current_stock

    assert_equal 70, stock.find { |s| s.name == "Quantanium" }.net_quantity
    assert_equal 20, stock.find { |s| s.name == "Titanium" }.net_quantity
  end

  test "current_stock omits fully withdrawn entries" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu, entry_type: :withdrawal)

    assert_empty @inventory.current_stock
  end

  test "destroying the inventory destroys its ledger entries" do
    create_list(:inventory_item, 2, inventory: @inventory)

    assert_difference "InventoryItem.count", -2 do
      @inventory.destroy
    end
  end
end
