# frozen_string_literal: true

json.array! @vehicle_loadouts, partial: "api/v1/vehicle_loadouts/vehicle_loadout", as: :vehicle_loadout, extended: true
