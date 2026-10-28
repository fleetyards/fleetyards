# frozen_string_literal: true

json.username entry.display_username
json.draw_position entry.draw_position
json.won_at entry.won_at.utc.iso8601
json.claim_deadline_at entry.claim_deadline_at.utc.iso8601
json.claimed_at entry.claimed_at.utc.iso8601 if entry.claimed_at.present?
json.forfeited_at entry.forfeited_at.utc.iso8601 if entry.forfeited_at.present?
