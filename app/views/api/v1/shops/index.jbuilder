# frozen_string_literal: true

json.items do
  json.array! @shops, partial: "api/v1/shops/shop", as: :shop
end
json.partial! "api/shared/meta", result: @shops
