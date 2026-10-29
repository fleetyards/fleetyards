# frozen_string_literal: true

json.items @entries do |entry|
  raffle = entry.raffle
  json.id entry.id
  json.raffle_id raffle.id
  json.raffle_title raffle.localized_title
  json.prize raffle.localized_prize if raffle.localized_prize.present?
  json.raffle_status raffle.status
  json.ends_at raffle.ends_at.utc.iso8601
  json.entered_at entry.created_at.utc.iso8601
  json.outcome entry.outcome
  json.claim_deadline_at entry.claim_deadline_at.utc.iso8601 if entry.claim_deadline_at.present?
end
json.partial! "api/shared/meta", result: @entries
