# frozen_string_literal: true

json.items do
  json.array! @shops, partial: "api/v1/shops/minimal", as: :shop
end
json.partial! "api/shared/meta", result: @shops
