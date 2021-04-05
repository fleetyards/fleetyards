# frozen_string_literal: true

json.cache! ['v1', fleet_membership] do
  json.partial! 'api/v1/fleet_memberships/base', member: fleet_membership
  json.partial! 'api/shared/dates', record: fleet_membership
end
