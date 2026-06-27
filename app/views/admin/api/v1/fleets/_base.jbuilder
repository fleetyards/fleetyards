# frozen_string_literal: true

json.id fleet.id
json.fid fleet.fid
json.name fleet.name
json.slug fleet.slug
json.description fleet.description
json.rsi_sid fleet.rsi_sid
json.ts fleet.ts
json.discord fleet.discord
json.youtube fleet.youtube
json.twitch fleet.twitch
json.guilded fleet.guilded
json.homepage fleet.homepage
json.public_fleet fleet.public_fleet
json.public_fleet_stats fleet.public_fleet_stats
json.logo do
  json.partial! "api/v1/shared/file", record: fleet, attr: :logo
end
json.background_image do
  json.partial! "api/v1/shared/file", record: fleet, attr: :background_image
end
ranked_roles = fleet.fleet_roles.select { |fleet_role| fleet_role.rank.present? }.sort_by(&:rank)
json.fleet_roles ranked_roles do |fleet_role|
  json.id fleet_role.id
  json.name fleet_role.name
  json.permanent fleet_role.permanent || false
  json.rank fleet_role.rank
end

json.partial! "api/shared/dates", record: fleet
