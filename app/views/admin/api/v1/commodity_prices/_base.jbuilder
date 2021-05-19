# frozen_string_literal: true

json.id commodity_price.id
json.price commodity_price.price
json.time_range commodity_price.time_range
json.created_at commodity_price.created_at
json.confirmed commodity_price.confirmed
json.type commodity_price.type
json.submitters do
  json.array! commodity_price.users, partial: 'admin/api/v1/commodity_prices/submitter', as: :submitter
end
