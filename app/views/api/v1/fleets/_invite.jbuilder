# frozen_string_literal: true

json.cache! ["v2", member, member.fleet, member.fleet.rsi_verification_cache_key] do
  json.partial!("api/v1/fleet_members/base", member:)
  json.fleet do
    json.partial! "api/v1/fleets/base", fleet: member.fleet, visitor: !member.accepted?
  end
end
