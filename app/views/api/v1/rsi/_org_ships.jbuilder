# encoding: utf-8
# frozen_string_literal: true

json.id user_ship.id
json.name user_ship.name
json.user do
  json.partial! 'api/v1/users/show', user: user_ship.user
end
json.ship do
  json.partial! 'api/v1/ships/show', ship: user_ship.ship
end
json.partial! 'api/shared/dates', record: user_ship
