# frozen_string_literal: true

json.cache! ["v1", member] do
  json.partial!("api/v1/fleet_memberships/base", member:)
  json.fleet do
    json.partial! "api/v1/fleets/minimal", fleet: member.fleet
  end
  json.partial! "api/shared/dates", record: member
end
