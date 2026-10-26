# frozen_string_literal: true

# A catalogue item a user means to buy in game, and how many. `item_price`
# pins the line to one of the places selling it; without a pin the cart sends
# the user to the cheapest.
class CartItem < ApplicationRecord
  MAX_PER_CART = 500
  MAX_QUANTITY = 99_999

  belongs_to :cart
  # Optional so the inclusion check runs before anything constantizes
  # `item_type`; `referenced_item_exists` requires the item itself.
  belongs_to :item, polymorphic: true, optional: true
  belongs_to :item_price, optional: true

  validates :item_type, inclusion: {in: ::InventoryLedgerEntry::ITEM_TYPES}
  validates :item_id, uniqueness: {scope: %i[cart_id item_type]}
  validates :quantity, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY}
  validate :referenced_item_exists
  validate :item_price_offers_item
  validate :cart_limit, on: :create

  private def referenced_item_exists
    return unless item_type.in?(::InventoryLedgerEntry::ITEM_TYPES)

    errors.add(:item_id, :blank) if item.blank?
  end

  # A shop's `sell` price is what the user pays, so only those can be picked.
  private def item_price_offers_item
    return if item_price.blank?
    return if item_price.sell? && item_price.item_type == item_type && item_price.item_id == item_id

    errors.add(:item_price_id, :not_offered)
  end

  private def cart_limit
    return if cart.blank?
    return if cart.cart_items.count < MAX_PER_CART

    errors.add(:base, :cart_limit_reached, count: MAX_PER_CART)
  end
end
