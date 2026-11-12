# frozen_string_literal: true

json.array! @flights, partial: "api/v1/fleet_squadron_flights/fleet_squadron_flight", as: :fleet_squadron_flight
