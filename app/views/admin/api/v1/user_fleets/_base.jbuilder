# frozen_string_literal: true

json.id membership.id
json.fleet_id membership.fleet_id
json.name membership.fleet.name
json.slug membership.fleet.slug
json.fid membership.fleet.fid
json.logo do
  json.partial! "api/v1/shared/file", record: membership.fleet, attr: :logo
end
json.role membership.fleet_role&.name
json.permanent membership.fleet_role&.permanent? || false
json.primary membership.primary
json.status membership.aasm.current_state
json.members_count membership.fleet.fleet_memberships.count
json.accepted_at membership.accepted_at&.utc&.iso8601

json.partial! "api/shared/dates", record: membership
