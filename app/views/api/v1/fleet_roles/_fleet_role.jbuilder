# frozen_string_literal: true

json.cache! ["v1", fleet_role] do
  json.partial! "api/v1/fleet_roles/base", fleet_role: fleet_role, extended: local_assigns.fetch(:extended, false)
end
