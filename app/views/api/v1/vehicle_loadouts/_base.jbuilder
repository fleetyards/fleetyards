# frozen_string_literal: true

json.id vehicle_loadout.id
json.name vehicle_loadout.name
json.active vehicle_loadout.active
json.url vehicle_loadout.url
json.url_source vehicle_loadout.url_source

json.partial! "api/shared/dates", record: vehicle_loadout
