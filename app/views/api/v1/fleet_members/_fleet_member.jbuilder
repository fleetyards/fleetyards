# frozen_string_literal: true

json.cache! ["v1", member] do
  json.partial! "api/v1/fleet_members/base", member: member
end

json.is_destroy_allowed(local_assigns.fetch(:is_destroy_allowed, false))
