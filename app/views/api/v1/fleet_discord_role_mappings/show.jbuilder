# frozen_string_literal: true

json.items @fleet_roles do |fleet_role|
  json.fleet_role_id fleet_role.id
  json.name fleet_role.name
  json.discord_role_id fleet_role.discord_role_id
end
