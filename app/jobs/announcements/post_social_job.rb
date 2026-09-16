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

    # The id recorded is the first post's, which is what addresses a thread:
    # every reply hangs off it, so it is the one link that opens the whole
    # thing.
    private def post(announcement, channel)
      case channel.to_s
      when "discord"
        ::Discord::Announcement.new(announcement:).run
        nil
      when "bluesky"
        post_bluesky_thread(announcement)
      when "x"
        post_x_thread(announcement)
      end
    end

    # Serial, and it has to be: each post names the one before it, so there is
    # nothing to parallelise. A failure partway leaves the posts already made
    # standing -- they cannot be unsent -- which is why the delivery records
    # the error and a human decides what to do rather than a retry re-running
    # the whole thread.
    private def post_bluesky_thread(announcement)
      client = ::Bsky::Post.new
      root = nil
      parent = nil

      Announcements::SocialPosts.call(announcement, limit: ::Bsky::Post::MAX_LENGTH).each do |text|
        created = client.create(text, root:, parent:)
        root ||= created
        parent = created
      end

      root&.uri
    end

    private def post_x_thread(announcement)
      client = ::XCom::Post.new
      first = nil
      previous = nil

      Announcements::SocialPosts.call(announcement, limit: ::XCom::Post::MAX_LENGTH).each do |text|
        previous = client.create(text, reply_to: previous)
        first ||= previous
      end

      first
    end
  end
end
