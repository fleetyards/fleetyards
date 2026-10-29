# frozen_string_literal: true

json.raffle_id @entry.raffle_id
json.raffle_title @entry.raffle.localized_title
json.claimed_at @entry.claimed_at.utc.iso8601
