# frozen_string_literal: true

json.array! @fleet_roles do |fleet_role|
  json.partial! "api/v1/fleet_roles/base", fleet_role: fleet_role, extended: true
end
