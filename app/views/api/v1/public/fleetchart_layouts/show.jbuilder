# frozen_string_literal: true

json.name @fleetchart_layout.name
json.colored @fleetchart_layout.colored
owner = @fleetchart_layout.user

json.username(owner.hide_owner? ? nil : owner.username)
json.public_hangar(owner.public_hangar && !owner.hide_owner?)
json.placements @placements, partial: "api/v1/fleetchart_layouts/placement", as: :placement
json.vehicles @vehicles, partial: "api/v1/public/vehicles/vehicle", as: :vehicle
