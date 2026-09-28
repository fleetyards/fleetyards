# frozen_string_literal: true

require "bsky/engagement"
require "discord/engagement"

module Announcements
  # Reads one delivery's engagement back from its platform.
  #
  # `retry: false`: the sweep comes round again within the hour, and a refresh
  # that failed leaves the last counts standing with their fetched-at time, so
  # the admin can see they are stale.
  class RefreshEngagementJob < Announcements::BaseJob
    sidekiq_options retry: false

    def perform(delivery_id)
      delivery = AnnouncementDelivery.find_by(id: delivery_id)
      return if delivery.blank? || !delivery.engagement_trackable?

      engagement = fetch(delivery)
      return if engagement.nil?

      delivery.update!(engagement:, engagement_fetched_at: Time.current)
    rescue ::Bsky::Engagement::Error, ::Discord::ApiClient::Error, Faraday::Error => e
      Rails.logger.warn("Announcement engagement refresh failed for #{delivery_id}: #{e.message}")
    end

    private def fetch(delivery)
      case delivery.channel
      when "bluesky"
        ::Bsky::Engagement.new.fetch(delivery.posted_parts.filter_map { |part| part["uri"] })
      when "discord"
        return nil unless ::Discord::Engagement.configured?

        ::Discord::Engagement.new.fetch(delivery.posted_parts, guild_id: delivery.engagement&.dig("guild_id"))
      end
    end
  end
end
