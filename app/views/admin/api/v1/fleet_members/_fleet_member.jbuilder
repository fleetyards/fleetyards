# frozen_string_literal: true

json.cache! ["v1", member] do
  json.partial!("admin/api/v1/fleet_members/base", member:)
end

online = online_status_for(member.user)
json.online online unless online.nil?
