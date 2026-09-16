# frozen_string_literal: true

require "bsky/post"
require "discord/announcement"
require "x_com/post"

module Announcements
  # Posts one announcement to one social channel.
  #
  # `retry: false`: a retry here is a duplicate post, not a second attempt --
  # nothing in the three APIs is idempotent, and a timeout that actually landed
  # would put the announcement out twice. A failed delivery is retried from the
  # admin instead, where a human can see whether the first one arrived.
  class PostSocialJob < Announcements::BaseJob
    sidekiq_options retry: false, queue: "notifications"

    def perform(announcement_id, channel)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?

      delivery = announcement.delivery_for(channel)
      delivery.attempts += 1
      delivery.save!

      unless configured?(channel)
        delivery.skip!(I18n.t("announcements.deliveries.not_configured"))
        return
      end

      external_id = post(announcement, channel)
      delivery.succeed!(external_id:)
    rescue => e
      Appsignal.report_error(e)
      delivery&.fail!(e.message)
    end

    private def configured?(channel)
      case channel.to_s
      when "discord" then ::Discord::Announcement.configured?
      when "bluesky" then ::Bsky::Post.configured?
      when "x" then ::XCom::Post.configured?
      else false
      end
    end

    private def post(announcement, channel)
      case channel.to_s
      when "discord"
        ::Discord::Announcement.new(announcement:).run
        nil
      when "bluesky"
        ::Bsky::Post.new.create(
          Announcements::SocialMessage.call(announcement, limit: ::Bsky::Post::MAX_LENGTH)
        )
      when "x"
        ::XCom::Post.new.create(
          Announcements::SocialMessage.call(announcement, limit: ::XCom::Post::MAX_LENGTH)
        )
      end
    end
  end
end
