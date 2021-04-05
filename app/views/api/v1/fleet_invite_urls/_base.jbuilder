# frozen_string_literal: true

json.token fleet_invite_url.token
json.url fleet_invite_url.url
json.expires_after fleet_invite_url.expires_after&.utc&.iso8601
json.expires_after_label distance_of_time_in_words(Time.zone.now.utc, fleet_invite_url.expires_after.utc) if fleet_invite_url.expires_after.present?
json.expired fleet_invite_url.expired?
json.limit fleet_invite_url.limit
json.limit_reached fleet_invite_url.limit_reached?
