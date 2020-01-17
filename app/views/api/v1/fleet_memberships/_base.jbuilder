# frozen_string_literal: true

json.username member.user.username
json.role member.role
json.role_Label FleetMembership.human_enum_name(:role, member.role)
json.invitation member.invitation
json.invite_sent_at_label I18n.l(member.created_at.utc, format: :label)
json.accepted_at member.accepted_at&.utc&.iso8601
json.accepted_at_label((I18n.l(member.accepted_at.utc, format: :label) if member.accepted_at.present?))
json.declined_at member.declined_at&.utc&.iso8601
json.declined_at_label((I18n.l(member.declined_at.utc, format: :label) if member.declined_at.present?))
json.avatar member.user.avatar.small.url
json.primary member.primary
json.hide_ships member.hide_ships
json.rsi_handle member.user.rsi_handle
json.homepage member.user.homepage
json.discord member.user.discord
json.youtube member.user.youtube
json.twitch member.user.twitch
