# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: hangar_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null
#
# Indexes
#
#  index_hangar_inventories_on_user_id_and_lower_name  (user_id, lower((name)::text)) UNIQUE
#  index_hangar_inventories_on_user_id_and_slug        (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HangarInventoryTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @inventory = create(:hangar_inventory, user: @user, name: "Area 18 Locker")
  end

  test "generates a slug from the name" do
    assert_equal "area-18-locker", @inventory.slug
  end

  test "names are unique per user but not across users" do
    duplicate = build(:hangar_inventory, user: @user, name: "area 18 locker")

    assert_not duplicate.valid?

    other = build(:hangar_inventory, user: create(:user), name: "Area 18 Locker")

    assert_predicate other, :valid?
  end

  test "current_stock nets deposits against withdrawals" do
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu)
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Titanium", quantity: 20, unit: :scu)

    stock = @inventory.current_stock

    assert_equal 70, stock.find { |s| s.name == "Quantanium" }.net_quantity
    assert_equal 20, stock.find { |s| s.name == "Titanium" }.net_quantity
  end

  test "current_stock omits fully withdrawn entries" do
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu)
    create(:hangar_inventory_item, hangar_inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu, entry_type: :withdrawal)

    assert_empty @inventory.current_stock
  end

  test "destroying the inventory destroys its ledger entries" do
    create_list(:hangar_inventory_item, 2, hangar_inventory: @inventory)

    assert_difference "HangarInventoryItem.count", -2 do
      @inventory.destroy
    end
  end
end
