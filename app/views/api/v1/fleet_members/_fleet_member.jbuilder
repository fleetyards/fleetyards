# frozen_string_literal: true

json.cache! ["v2", member] do
  json.partial! "api/v1/fleet_members/base", member: member
end

# Outside the fragment: the key is the membership, and nothing about presence
# touches it. Absent rather than false when the reader is not entitled to an
# answer -- an omission and a claim that somebody is offline differ.
online = online_status_for(member.user)
json.online online unless online.nil?

json.is_destroy_allowed(local_assigns.fetch(:is_destroy_allowed, false))

if local_assigns.fetch(:with_capabilities, false)
  json.capabilities member.capabilities.transform_keys { |key| key.to_s.camelize(:lower) }
end
