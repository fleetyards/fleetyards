json.id member.id
json.username member.user.username
json.role member.role
json.role_Label FleetMembership.human_enum_name(:role, member.role)
json.status member.aasm.current_state
if member.invited_at.present?
  json.invited_at member.invited_at.utc.iso8601
  json.invited_at_label I18n.l(member.invited_at.utc, format: :label)
end
if member.requested_at.present?
  json.requested_at member.requested_at&.utc&.iso8601
  json.requested_at_label I18n.l(member.requested_at.utc, format: :label)
end
if member.accepted_at.present?
  json.accepted_at member.accepted_at&.utc&.iso8601
  json.accepted_at_label I18n.l(member.accepted_at.utc, format: :label)
end
if member.declined_at.present?
  json.declined_at member.declined_at&.utc&.iso8601
  json.declined_at_label I18n.l(member.declined_at.utc, format: :label)
end
json.avatar member.user.avatar.small.url
json.rsi_handle member.user.rsi_handle
json.homepage member.user.homepage
json.discord member.user.discord
json.youtube member.user.youtube
json.twitch member.user.twitch
json.guilded member.user.guilded
json.ships_filter member.ships_filter
json.hangar_group_id member.hangar_group_id
json.hangar_updated_at member.user.hangar_updated_at&.utc&.iso8601
json.fleet_slug member.fleet.slug
json.fleet_name member.fleet.name
json.primary member.primary
