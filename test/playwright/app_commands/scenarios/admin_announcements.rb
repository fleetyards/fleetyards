# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_announcements scenario test data..."

admin_user = AdminUser.find_or_create_by!(username: "admin_announcements") do |u|
  u.email = "admin_announcements@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

announcement = Announcement.create!(
  admin_user:,
  title: "Trade routes for your ship",
  body: "Trade routes are now ranked for the ship you **fly**.",
  link: "/tools/trade-routes/",
  status: :published,
  published_at: 2.hours.ago,
  recipients_count: 57_000,
  notify_users: true,
  post_discord: true,
  post_bluesky: true,
  post_x: true
)

sent = {status: "succeeded", delivered_at: 2.hours.ago, attempts: 1}

announcement.deliveries.create!(channel: "in_app", **sent)
announcement.deliveries.create!(
  channel: "discord", **sent,
  posted_parts: [{"index" => 0, "message_id" => "111", "channel_id" => "222"}],
  engagement: {"reactions" => [{"emoji" => "🚀", "count" => 14}, {"emoji" => "👍", "count" => 6}], "guild_id" => "333"},
  engagement_fetched_at: 10.minutes.ago
)
announcement.deliveries.create!(
  channel: "bluesky", **sent,
  external_id: "at://did:plc:fleetyards/app.bsky.feed.post/3k",
  posted_parts: [{"uri" => "at://did:plc:fleetyards/app.bsky.feed.post/3k", "cid" => "c"}],
  engagement: {"likes" => 42, "reposts" => 7, "replies" => 3, "quotes" => 1},
  engagement_fetched_at: 10.minutes.ago
)
announcement.deliveries.create!(channel: "x", status: "failed", attempts: 1, error: "X API error 429: Too Many Requests")

Announcement.create!(
  admin_user:,
  title: "Draft for next week",
  body: "Not sent yet.",
  status: :draft,
  notify_users: true
)

Rails.logger.info "E2E: Created admin_announcements scenario test data"
