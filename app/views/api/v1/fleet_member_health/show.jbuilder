# frozen_string_literal: true

checks = {
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
# Only an org the fleet proved is its own: anyone can type any SID.
json.rsi_member_count @fleet.verified_rsi_member_count
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

json.admins do
  json.partial! "api/v1/fleet_member_health/check", check: @admins, leader_role_ids: @leader_role_ids
  json.candidates (@admin_candidates || []), partial: "api/v1/fleet_member_health/member", as: :membership, leader_role_ids: @leader_role_ids
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
