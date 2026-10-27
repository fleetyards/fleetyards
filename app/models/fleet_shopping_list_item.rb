# frozen_string_literal: true

# A catalogue item on a fleet's shopping list, and how many each member needs.
class FleetShoppingListItem < ApplicationRecord
  belongs_to :fleet_shopping_list
  belongs_to :item, polymorphic: true, optional: true

  validates :item_type, inclusion: {in: ::InventoryLedgerEntry::ITEM_TYPES}
  validates :item_id, uniqueness: {scope: %i[fleet_shopping_list_id item_type]}
  validates :quantity, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: CartItem::MAX_QUANTITY}

  # Read by Carts::TripPlan, which prices these lines as it does a cart's. A
  # fleet list carries no pin, so every line goes to its cheapest place.
  def item_price_id = nil
end
