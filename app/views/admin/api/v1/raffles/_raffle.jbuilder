# frozen_string_literal: true

json.id raffle.id
json.title raffle.title
json.description raffle.description if raffle.description.present?
if raffle.model.present?
  json.prize do
    json.partial! "api/v1/raffles/prize", model: raffle.model
  end
end
json.code_set raffle.code.present?
json.masked_code raffle.masked_code if raffle.code.present?
json.partial!("api/v1/raffles/images", raffle:)
json.starts_at raffle.starts_at.utc.iso8601
json.run_days raffle.run_days
json.ends_at raffle.ends_at.utc.iso8601
json.claim_period_days raffle.claim_period_days
json.published raffle.published
json.status raffle.status
json.entries_count local_assigns.fetch(:entries_count) { raffle.entries.count }
json.drawn_at raffle.drawn_at.utc.iso8601 if raffle.drawn_at.present?
json.drawn_by raffle.drawn_by.username if raffle.drawn_by.present?
json.concluded_at raffle.concluded_at.utc.iso8601 if raffle.concluded_at.present?
json.start_announced_at raffle.start_announced_at.utc.iso8601 if raffle.start_announced_at.present?
json.last_day_announced_at raffle.last_day_announced_at.utc.iso8601 if raffle.last_day_announced_at.present?

social_post = Raffles::SocialPost.new(raffle)
json.social_posts do
  json.start social_post.text(:start, Raffles::SocialPost::X)
  json.last_day social_post.text(:last_day, Raffles::SocialPost::X)
end

current_winner = raffle.current_winner if raffle.drawn?
if current_winner.present?
  json.current_winner do
    json.partial! "admin/api/v1/raffle_entries/entry", entry: current_winner
  end
end

json.partial! "api/shared/dates", record: raffle
