# frozen_string_literal: true

viewer_entry = local_assigns[:viewer_entry]

json.id raffle.id
json.title raffle.title
json.description raffle.description if raffle.description.present?
if raffle.model.present?
  json.prize do
    json.partial! "api/v1/raffles/prize", model: raffle.model
  end
end
json.partial!("api/v1/raffles/images", raffle:)
json.starts_at raffle.starts_at.utc.iso8601
json.ends_at raffle.ends_at.utc.iso8601
json.run_days raffle.run_days
json.claim_period_days raffle.claim_period_days
json.status raffle.status
json.entries_count local_assigns.fetch(:entries_count) { raffle.entries.count }
json.drawn_at raffle.drawn_at.utc.iso8601 if raffle.drawn_at.present?
json.concluded_at raffle.concluded_at.utc.iso8601 if raffle.concluded_at.present?

winners = raffle.drawn? ? raffle.won_entries.to_a : []
current_winner = winners.find(&:current_winner?)
if current_winner.present?
  json.current_winner do
    json.partial! "api/v1/raffles/winner", entry: current_winner
  end
end
json.forfeited_winners winners.reject(&:current_winner?), partial: "api/v1/raffles/winner", as: :entry

json.conditions_version Raffle::CONDITIONS_VERSION

won = viewer_entry.present? && viewer_entry.id == current_winner&.id
json.entered viewer_entry.present?
json.won won
json.claimable won && current_winner.claimable?
json.claimed won && current_winner.claimed_at.present?
