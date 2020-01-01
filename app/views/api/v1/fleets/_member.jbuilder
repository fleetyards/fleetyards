# frozen_string_literal: true

json.cache! ['v1', member] do
  json.username member.user.username
  json.role member.role
  json.role_Label FleetMembership.human_enum_name(:role, member.role)
  json.avatar member.user.avatar.small.url
  json.partial! 'api/shared/dates', record: member
end
