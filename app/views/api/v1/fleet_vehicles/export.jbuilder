# frozen_string_literal: true

json.array! @vehicles, partial: "api/v1/fleet_vehicles/export", as: :vehicle
