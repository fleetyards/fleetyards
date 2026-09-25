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
json.allies_fleet fleet.allies_fleet
json.allies_fleet_stats fleet.allies_fleet_stats
json.allies_fleet_members fleet.allies_fleet_members
json.squadrons_enabled fleet.squadrons_enabled
json.default_timezone fleet.default_timezone
json.logo do
  json.partial! "api/v1/shared/file", record: fleet, attr: :logo
end
json.contract_covers do
  ::Fleet::CONTRACT_COVER_ATTACHMENTS.each do |kind, attachment|
    json.set! kind do
      json.partial! "api/v1/shared/file", record: fleet, attr: attachment
    end
  end
end

json.background_image do
  json.partial! "api/v1/shared/file", record: fleet, attr: :background_image
end

json.partial! "api/shared/dates", record: fleet
