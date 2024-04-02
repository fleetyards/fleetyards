# frozen_string_literal: true

json.id commodity_price.id
json.price commodity_price.price.to_f
json.time_range commodity_price.time_range
json.created_at commodity_price.created_at
json.confirmed commodity_price.confirmed
json.type commodity_price.type
json.submitters do
  json.array! commodity_price.users, partial: "admin/api/v1/commodity_prices/submitter", as: :submitter
end

if local_assigns.fetch(:extended, false)
  json.shop_commodity do
    json.null! if commodity_price.shop_commodity.blank?
    json.partial!("admin/api/v1/shop_commodities/base", shop_commodity: commodity_price.shop_commodity, extended: true) if commodity_price.shop_commodity.present?
  end
end

json.partial! "api/shared/dates", record: commodity_price
