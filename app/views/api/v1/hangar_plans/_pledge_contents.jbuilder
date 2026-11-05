# frozen_string_literal: true

json.pledge_ships ships do |ship|
  json.id ship.id
  json.name ship.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: ship.model
  end
end
json.pledge_items items do |item|
  json.id item.id
  json.name item.name
  json.kind item.kind
  json.quantity item.quantity
end
