# frozen_string_literal: true

json.id fleet_squadron.id
json.name fleet_squadron.name
json.slug fleet_squadron.slug
json.short_description fleet_squadron.short_description
json.color fleet_squadron.color
json.team fleet_squadron.team
json.flights_enabled fleet_squadron.flights_enabled
json.discord_channel_id fleet_squadron.discord_channel_id
json.classifications fleet_squadron.classifications
json.foci fleet_squadron.foci
json.foci_labels ::Model.focus_labels(fleet_squadron.foci)

if fleet_squadron.icon.attached?
  json.icon do
    json.partial! "api/v1/shared/file", record: fleet_squadron, attr: :icon
  end
else
  json.icon nil
end

json.partial! "api/shared/dates", record: fleet_squadron
