# frozen_string_literal: true

json.name @fleetchart_layout.name
json.colored @fleetchart_layout.colored
json.username @fleetchart_layout.user.username
json.public_hangar @fleetchart_layout.user.public_hangar
json.placements @placements, partial: "api/v1/fleetchart_layouts/placement", as: :placement
json.vehicles @vehicles, partial: "api/v1/public/vehicles/vehicle", as: :vehicle
