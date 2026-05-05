# frozen_string_literal: true

json.id fleet.id
json.fid fleet.fid
json.rsi_sid fleet.rsi_sid
json.ts fleet.ts
json.discord fleet.discord
json.youtube fleet.youtube
json.twitch fleet.twitch
json.guilded fleet.guilded
json.homepage fleet.homepage
json.name fleet.name
json.description fleet.description
json.slug fleet.slug
json.public_fleet fleet.public_fleet
json.public_fleet_stats fleet.public_fleet_stats
json.default_timezone fleet.default_timezone
json.logo do
  json.partial! "api/v1/shared/file", record: fleet, attr: :logo
end
json.background_image do
  json.partial! "api/v1/shared/file", record: fleet, attr: :background_image
end

json.partial! "api/shared/dates", record: fleet
