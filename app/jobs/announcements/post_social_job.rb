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
  #
  # A thread is posted one call at a time, so a failure partway through leaves
  # the posts already made standing. Each one is written to the delivery as it
  # lands and the next attempt resumes from there -- which is what makes the
  # admin's retry safe to press on a half-posted thread.
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

      post(announcement, channel, delivery)
      delivery.succeed!(external_id: external_id_for(channel, delivery))
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
    private def external_id_for(channel, delivery)
      first = delivery.first_posted_part
      return nil if first.blank?

      (channel.to_s == "x") ? first["id"] : first["uri"]
    end

    private def post(announcement, channel, delivery)
      case channel.to_s
      when "discord" then post_discord(announcement, delivery)
      when "bluesky" then post_bluesky_thread(announcement, delivery)
      when "x" then post_x_thread(announcement, delivery)
      end
    end

    private def post_discord(announcement, delivery)
      ::Discord::Announcement.new(announcement:, from: delivery.posted_count).run do |index|
        delivery.record_part!({"index" => index})
      end
    end

    private def post_bluesky_thread(announcement, delivery)
      client = ::Bsky::Post.new
      root = reference(delivery.first_posted_part)
      parent = reference(delivery.last_posted_part)

      remaining(announcement, ::Announcements::Platform::BLUESKY, delivery).each do |text|
        created = client.create(text, root:, parent:)
        delivery.record_part!({"uri" => created.uri, "cid" => created.cid})
        root ||= created
        parent = created
      end
    end

    private def post_x_thread(announcement, delivery)
      client = ::XCom::Post.new
      previous = delivery.last_posted_part&.fetch("id", nil)

      remaining(announcement, ::Announcements::Platform::X, delivery).each do |text|
        previous = client.create(text, reply_to: previous)
        delivery.record_part!({"id" => previous})
      end
    end

    private def remaining(announcement, platform, delivery)
      Announcements::SocialPosts.call(announcement, platform:).drop(delivery.posted_count)
    end

    private def reference(part)
      return nil if part.blank?

      ::Bsky::Post::Record.new(part["uri"], part["cid"])
    end
  end
end
