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
json.logo((fleet.logo.small.url if fleet.logo.present?))
json.background_image((fleet.background_image.url if fleet.background_image.present?))
