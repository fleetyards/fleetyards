# frozen_string_literal: true

json.array! @fleet_squadron_roles do |fleet_squadron_role|
  json.partial! "api/v1/fleet_squadron_roles/base", fleet_squadron_role:
end
