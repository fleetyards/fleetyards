# frozen_string_literal: true

json.cache! ['v1', fleet] do
  json.name fleet.name
  json.sid fleet.sid
  json.logo fleet.logo
  json.members do
    json.array! fleet.members, partial: 'api/v1/fleets/member', as: :member
  end
  json.rsi_members do
    json.array! fleet.rsi_members, partial: 'api/v1/fleets/rsi_member', as: :rsi_member
  end
  json.archetype fleet.archetype
  json.main_activity fleet.main_activity
  json.secondary_activity fleet.secondary_activity
  json.recruiting fleet.recruiting
  json.commitment fleet.commitment
  json.rpg fleet.rpg
  json.exclusive fleet.exclusive
  json.member_count fleet.member_count
  json.partial! 'api/shared/dates', record: fleet
end
