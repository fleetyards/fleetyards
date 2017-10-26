# encoding: utf-8
# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name
json.purchased vehicle.purchased
json.sale_notify vehicle.sale_notify
json.model do
  json.partial! 'api/v1/models/minimal', model: vehicle.ship
end
json.user do
  json.partial! 'api/v1/users/base', user: vehicle.user
end
json.partial! 'api/shared/dates', record: vehicle
