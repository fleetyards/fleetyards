# frozen_string_literal: true

# The member partial badges the invitee's handle, and verifying it touches
# neither the membership nor the fleet.
json.cache! ["v3", member, member.fleet, member.fleet.rsi_verification_cache_key, member.user.rsi_handle_verification_cache_key] do
  json.partial!("api/v1/fleet_members/base", member:)
  json.fleet do
    json.partial! "api/v1/fleets/base", fleet: member.fleet, visitor: !member.accepted?
  end
end
