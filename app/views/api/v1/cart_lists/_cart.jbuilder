# frozen_string_literal: true

json.id cart.id
json.name cart.name
json.active cart.active?
json.items_count cart.has_attribute?(:items_count) ? cart.items_count : cart.cart_items.sum(:quantity)
json.partial! "api/shared/dates", record: cart
