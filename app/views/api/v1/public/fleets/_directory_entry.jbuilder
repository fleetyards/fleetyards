# frozen_string_literal: true

# Narrower than the fleet page on purpose: no settings and no features, which
# are per fleet and would cost a lookup for every row.
json.cache! ["v1", "directory", fleet, fleet.rsi_verification_cache_key] do
  json.id fleet.id
  json.fid fleet.fid
  json.slug fleet.slug
  json.name fleet.name
  json.rsi_sid fleet.public_rsi_sid
  json.member_count fleet.rsi_member_count
  json.alignment fleet.alignment
  json.primary_activity fleet.primary_activity
  json.secondary_activity fleet.secondary_activity
  json.commitment fleet.commitment
  json.language fleet.language
  json.roleplay fleet.roleplay
  json.recruiting fleet.recruiting
  json.default_timezone fleet.default_timezone
  json.logo do
    json.partial! "api/v1/shared/file", record: fleet, attr: :logo
  end
  json.partial! "api/shared/dates", record: fleet
end
