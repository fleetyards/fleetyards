# frozen_string_literal: true

checks = {
  admins: @admins,
  unverified_members: @unverified,
  members_without_rsi_handle: @without_rsi_handle,
  inactive_members: @inactive,
  waiting_join_requests: @join_requests,
  unanswered_invitations: @invitations,
  members_without_discord: @without_discord,
  members_without_squadron: @without_squadron
}

json.inactive_days @inactive_days
json.fleet_rsi_verified @fleet.rsi_verified?
json.rsi_member_count(@fleet.rsi_sid.present? ? @fleet.rsi_member_count : nil)
json.member_count @members.count
json.hidden_ships_count @hidden_ships_count

checks.each do |key, check|
  if check
    json.set! key do
      json.partial! "api/v1/fleet_member_health/check", check:, leader_role_ids: @leader_role_ids
    end
  else
    json.set! key, nil
  end
end

if @empty_roles
  json.empty_roles @empty_roles, partial: "api/v1/fleet_roles/base", as: :fleet_role
else
  json.empty_roles nil
end

if @invite_urls
  json.stale_invite_urls do
    json.total_count @invite_urls[:total_count]
    json.items @invite_urls[:items] do |invite_url|
      json.token invite_url.token
      json.url invite_url.url
      json.created_by invite_url.user&.username
      json.created_at invite_url.created_at.utc.iso8601
      json.expires_after invite_url.expires_after&.utc&.iso8601
      json.limit invite_url.limit
      json.usage_count invite_url.usage_count
    end
  end
else
  json.stale_invite_urls nil
end

if @empty_squadrons
  json.empty_squadrons do
    json.total_count @empty_squadrons[:total_count]
    json.items @empty_squadrons[:items] do |squadron|
      json.id squadron.id
      json.name squadron.name
      json.slug squadron.slug
      json.team squadron.team
      json.created_at squadron.created_at.utc.iso8601
    end
  end
else
  json.empty_squadrons nil
end
