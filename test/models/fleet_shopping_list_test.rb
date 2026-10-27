# frozen_string_literal: true

require "test_helper"

class FleetShoppingListTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @list = create(:fleet_shopping_list)
    @armor = create(:equipment)
    @helmet = create(:equipment)
  end

  test "publishing a cart copies items and quantities, not pins" do
    cart = create(:cart, user: @user)
    price = create(:item_price, item: @armor, price_type: "sell", time_range: nil)
    create(:cart_item, cart:, item: @armor, quantity: 3, item_price: price)
    create(:fleet_shopping_list_item, fleet_shopping_list: @list, item: @helmet)

    @list.replace_items_from!(cart)

    assert_equal [[@armor.id, 3]], @list.fleet_shopping_list_items.pluck(:item_id, :quantity)
  end

  test "publishing gives every line its own timestamp" do
    cart = create(:cart, user: @user)
    create_list(:equipment, 21).each { |item| create(:cart_item, cart:, item:) }

    @list.replace_items_from!(cart)

    assert_equal 21, @list.fleet_shopping_list_items.distinct.count(:created_at)
  end

  test "copying adds to what the cart holds, capped at the cart's limit" do
    create(:fleet_shopping_list_item, fleet_shopping_list: @list, item: @armor, quantity: 2)
    create(:fleet_shopping_list_item, fleet_shopping_list: @list, item: @helmet, quantity: CartItem::MAX_QUANTITY)
    cart = create(:cart, user: @user)
    create(:cart_item, cart:, item: @armor, quantity: 1)
    create(:cart_item, cart:, item: @helmet, quantity: 5)

    @list.copy_items_to!(cart)

    assert_equal({@armor.id => 3, @helmet.id => CartItem::MAX_QUANTITY}, cart.cart_items.pluck(:item_id, :quantity).to_h)
  end

  test "copying skips an item gone from the catalogue" do
    create(:fleet_shopping_list_item, fleet_shopping_list: @list, item: @armor)
    create(:fleet_shopping_list_item, fleet_shopping_list: @list, item: @helmet)
    @helmet.delete
    cart = create(:cart, user: @user)

    @list.copy_items_to!(cart)

    assert_equal [@armor.id], cart.cart_items.pluck(:item_id)
  end

  test "a fleet holds a limited number of lists" do
    fleet = @list.fleet
    FleetShoppingList.insert_all!(Array.new(FleetShoppingList::MAX_PER_FLEET - 1) { |n| {fleet_id: fleet.id, name: "Bulk #{n}"} })

    list = fleet.fleet_shopping_lists.new(name: "One too many")

    refute_predicate list, :valid?
    assert_includes list.errors.details[:base].pluck(:error), :fleet_shopping_list_limit_reached
  end
end
