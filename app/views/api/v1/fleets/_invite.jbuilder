# frozen_string_literal: true

json.cache! ['v1', member] do
  json.partial! 'api/v1/fleet_memberships/base', member: member
  json.fleet do
    json.partial! 'api/v1/fleets/base', fleet: member.fleet
  end
  json.partial! 'api/shared/dates', record: member
end
