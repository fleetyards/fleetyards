# frozen_string_literal: true

json.cache! ["v1", shop_commodity] do
  json.partial!("admin/api/v1/shop_commodities/base", shop_commodity:)
  json.item do
    json.partial! "admin/api/v1/#{shop_commodity.category.pluralize}/base", shop_commodity.category.to_sym => shop_commodity.commodity_item
  end
  json.partial! "api/shared/dates", record: shop_commodity
end
