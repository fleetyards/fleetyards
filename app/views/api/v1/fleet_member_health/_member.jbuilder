# frozen_string_literal: true

json.id membership.id
json.username membership.user.username
json.nickname membership.nickname
if membership.user.avatar.attached?
  json.avatar do
    json.partial! "api/v1/shared/file", record: membership.user, attr: :avatar
  end
else
  json.avatar nil
end
if membership.fleet_role.present?
  json.fleet_role do
    json.partial! "api/v1/fleet_roles/base", fleet_role: membership.fleet_role
  end
else
  json.fleet_role nil
end
json.leader leader_role_ids.include?(membership.fleet_role_id)
json.last_active_at membership.user.last_active_at&.utc&.iso8601
json.accepted_at membership.accepted_at&.utc&.iso8601
json.requested_at membership.requested_at&.utc&.iso8601
json.invited_at membership.invited_at&.utc&.iso8601
json.invited_by membership.inviter&.username
json.rsi_handle membership.user.rsi_handle.presence
json.discord_profile_url membership.user.discord_profile_url
json.verification_gap membership.verification_gap
json.rsi_organizations_checked_at membership.user.rsi_organizations_checked_at&.utc&.iso8601
json.verification_reminded_at local_assigns.fetch(:reminders, {})[membership.id]&.utc&.iso8601
