# frozen_string_literal: true

json.id entry.id
json.username entry.display_username
json.account_deleted entry.user_id.nil?
json.masked_email entry.masked_email if entry.email.present?
json.conditions_accepted_at entry.conditions_accepted_at.utc.iso8601
json.conditions_version entry.conditions_version
json.draw_position entry.draw_position if entry.draw_position.present?
json.won_at entry.won_at.utc.iso8601 if entry.won_at.present?
json.claim_deadline_at entry.claim_deadline_at.utc.iso8601 if entry.claim_deadline_at.present?
json.claimed_at entry.claimed_at.utc.iso8601 if entry.claimed_at.present?
json.claimed_by entry.claimed_by.username if entry.claimed_by.present?
json.forfeited_at entry.forfeited_at.utc.iso8601 if entry.forfeited_at.present?
json.verification_sent_at entry.verification_sent_at.utc.iso8601 if entry.verification_sent_at.present?
json.claimable entry.claimable?
json.created_at entry.created_at.utc.iso8601
