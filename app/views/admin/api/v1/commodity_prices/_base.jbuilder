# frozen_string_literal: true

json.id commodity_price.id
json.price commodity_price.price
json.time_range commodity_price.time_range
json.created_at commodity_price.created_at
json.confirmed commodity_price.confirmed
json.type commodity_price.type
json.submitter do
  json.id commodity_price.submitted_by
  json.username commodity_price.submitter&.username
end
