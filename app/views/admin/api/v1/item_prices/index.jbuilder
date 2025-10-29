# frozen_string_literal: true

json.items do
  json.array! @item_prices, partial: "admin/api/v1/item_prices/item_price", as: :item_price
end
json.partial! "api/shared/meta", result: @item_prices
