# frozen_string_literal: true

require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  test "rejects an item type outside the catalogues without loading it" do
    cart_item = build(:cart_item, item_type: "Model", item_id: create(:model).id)

    assert_not cart_item.valid?
    assert cart_item.errors.added?(:item_type, :inclusion, value: "Model")
  end

  test "rejects an item that does not exist" do
    cart_item = build(:cart_item, item_type: "Commodity", item_id: SecureRandom.uuid)

    assert_not cart_item.valid?
    assert cart_item.errors.added?(:item_id, :blank)
  end

  test "holds an item once per user" do
    existing = create(:cart_item)

    assert_not build(:cart_item, user: existing.user, item: existing.item).valid?
    assert build(:cart_item, item: existing.item).valid?
  end

  test "accepts only a sell price of its own item as the pin" do
    cart_item = create(:cart_item)
    own_sell = create(:item_price, item: cart_item.item, price_type: "sell", time_range: nil)
    own_buy = create(:item_price, item: cart_item.item, price_type: "buy", time_range: nil)
    other_sell = create(:item_price, item: create(:commodity), price_type: "sell", time_range: nil)

    assert cart_item.update(item_price: own_sell)
    assert_not cart_item.update(item_price: own_buy)
    assert_not cart_item.update(item_price: other_sell)
    assert cart_item.errors.added?(:item_price_id, :not_offered)
  end

  test "stops at the per-user limit" do
    user = create(:user)
    now = Time.current
    CartItem.insert_all(Array.new(CartItem::MAX_PER_USER) do
      {user_id: user.id, item_type: "Commodity", item_id: SecureRandom.uuid, quantity: 1, created_at: now, updated_at: now}
    end)
    cart_item = build(:cart_item, user:)

    assert_not cart_item.valid?
    assert cart_item.errors.added?(:base, :cart_limit_reached, count: CartItem::MAX_PER_USER)
  end

  test "pin is cleared when its price row goes away" do
    cart_item = create(:cart_item)
    price = create(:item_price, item: cart_item.item, price_type: "sell", time_range: nil)
    cart_item.update!(item_price: price)

    price.destroy!

    assert_nil cart_item.reload.item_price_id
  end

  test "goes with the catalogue item it is for" do
    cart_item = create(:cart_item)

    cart_item.item.destroy!

    assert_not CartItem.exists?(cart_item.id)
  end
end
