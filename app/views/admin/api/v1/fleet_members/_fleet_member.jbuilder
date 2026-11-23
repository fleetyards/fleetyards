# frozen_string_literal: true

# The role is in the key: a renamed role touches only the fleet.
json.cache! ["v3", member, member.fleet_role, member.user.avatar_cache_key] do
  json.partial!("admin/api/v1/fleet_members/base", member:)
end

online = online_status_for(member.user)
json.online online unless online.nil?
