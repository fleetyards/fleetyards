# frozen_string_literal: true

json.cache! ["v1", member] do
  json.partial! "api/v1/fleet_members/base", member: member
end
