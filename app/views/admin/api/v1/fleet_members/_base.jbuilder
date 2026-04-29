# frozen_string_literal: true

json.id member.id
json.user_id member.user_id
json.username member.user.username
json.email member.user.email
json.avatar do
  json.partial! "api/v1/shared/file", record: member.user, attr: :avatar
end
json.rsi_handle member.user.rsi_handle
json.role member.fleet_role&.name
json.status member.aasm.current_state
json.accepted_at member.accepted_at&.utc&.iso8601
json.last_active_at member.user.last_active_at&.utc&.iso8601

json.partial! "api/shared/dates", record: member
