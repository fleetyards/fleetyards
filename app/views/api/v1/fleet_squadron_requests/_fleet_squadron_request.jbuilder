# frozen_string_literal: true

json.id fleet_squadron_request.id
json.member do
  json.partial! "api/v1/fleet_members/fleet_member", member: fleet_squadron_request.fleet_membership
end
json.partial! "api/shared/dates", record: fleet_squadron_request
