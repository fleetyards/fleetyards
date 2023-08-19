# frozen_string_literal: true

json.cache! ["v1", member, member.fleet] do
  json.partial!("api/v1/fleet_members/base", member:)
  json.fleet do
    json.partial! "api/v1/fleets/base", fleet: member.fleet
  end
end
