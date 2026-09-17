# frozen_string_literal: true

json.id announcement.id
json.title announcement.title
json.body announcement.body
json.discord_parts announcement.discord_parts
json.social_parts announcement.social_parts
json.link announcement.link if announcement.link.present?
json.icon announcement.icon
json.status announcement.status
json.publish_at announcement.publish_at.utc.iso8601 if announcement.publish_at.present?
json.published_at announcement.published_at.utc.iso8601 if announcement.published_at.present?
json.recipients_count announcement.recipients_count if announcement.recipients_count.present?
json.notify_users announcement.notify_users
json.post_discord announcement.post_discord
json.post_bluesky announcement.post_bluesky
json.post_x announcement.post_x
json.publishable announcement.publishable?
json.last_tested_at announcement.last_tested_at.utc.iso8601 if announcement.last_tested_at.present?
json.author announcement.admin_user&.username if announcement.admin_user.present?

json.deliveries do
  json.array! announcement.deliveries.sort_by(&:channel) do |delivery|
    json.channel delivery.channel
    json.status delivery.status
    json.external_id delivery.external_id if delivery.external_id.present?
    json.error delivery.error if delivery.error.present?
    json.delivered_at delivery.delivered_at.utc.iso8601 if delivery.delivered_at.present?
    json.attempts delivery.attempts
  end
end

json.partial! "api/shared/dates", record: announcement
