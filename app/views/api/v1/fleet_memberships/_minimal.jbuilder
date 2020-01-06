# frozen_string_literal: true

json.cache! ['v1', member] do
  json.partial! 'api/v1/fleet_memberships/base', record: member
  json.partial! 'api/shared/dates', record: member
end
