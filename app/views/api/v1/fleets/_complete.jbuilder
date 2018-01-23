# frozen_string_literal: true

json.cache! ['v1', fleet] do
  json.partial! 'api/v1/fleets/base', fleet: fleet
  json.members do
    json.array! fleet.members, partial: 'api/v1/fleets/member', as: :member
  end
  json.rsi_members do
    json.array! fleet.rsi_members, partial: 'api/v1/fleets/rsi_member', as: :rsi_member
  end
  json.partial! 'api/shared/dates', record: fleet
end
