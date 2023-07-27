# frozen_string_literal: true

json.items do
  json.array! @shop_commodities, partial: "admin/api/v1/shop_commodities/minimal", as: :shop_commodity
end
json.partial! "api/shared/meta", result: @shop_commodities
