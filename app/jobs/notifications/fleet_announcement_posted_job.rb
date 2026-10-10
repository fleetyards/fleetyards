# frozen_string_literal: true

require "discord/event_announcement"

module Notifications
  # Tells a fleet that its officers posted something. Run off the request
  # because the audience is the whole fleet, which can be hundreds of members.
  class FleetAnnouncementPostedJob < Notifications::BaseJob
    # A retry would notify everybody already reached a second time. Each member
    # is handled on their own instead, so one failure costs that member only.
    sidekiq_options retry: false

    EXCERPT_LENGTH = 200

    # Discord refuses a message longer than this.
    DISCORD_LIMIT = 2000

    def perform(announcement_id)
      announcement = FleetAnnouncement.find_by(id: announcement_id)
      # Taken down or run out before the queue reached it: nothing to tell.
      return if announcement.blank? || !FleetAnnouncement.active.exists?(announcement.id)

      fleet = announcement.fleet
      return if fleet.blank? || fleet.discarded?

      notify_members(fleet, announcement)
      post_to_discord(fleet, announcement)
    end

    private def notify_members(fleet, announcement)
      fleet.fleet_memberships.kept.accepted.includes(:user).find_each do |membership|
        user = membership.user
        next if user.blank? || user.id == announcement.author_id

        notify(user, fleet, announcement)
      rescue => e
        Rails.logger.error("[FleetAnnouncementPostedJob] #{user&.id} not notified: #{e.class}: #{e.message}")
      end
    end

    # In the reader's own language: the title and body are stored, and one fleet
    # reaches members who do not share one.
    private def notify(user, fleet, announcement)
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user: user,
          type: :fleet_announcement_posted,
          title: I18n.t("notifications.fleet_announcement.posted.title", fleet: fleet.name),
          body: I18n.t("notifications.fleet_announcement.posted.body",
            author: announcement.author&.username || fleet.name,
            excerpt: excerpt(announcement.body)),
          link: "/fleets/#{fleet.slug}/",
          icon: "fa-duotone fa-bullhorn",
          record: announcement
        )
      end
    end

    private def post_to_discord(fleet, announcement)
      ::Discord::EventAnnouncement.fleet_targets(fleet).each do |target|
        ::Discord::EventAnnouncement.enqueue(fleet, target, discord_content(fleet, announcement))
      end
    end

    private def discord_content(fleet, announcement)
      heading = I18n.t("discord.fleet_announcement.title", fleet: fleet.name)

      "**#{heading}**\n#{announcement.body}".truncate(DISCORD_LIMIT)
    end

    private def excerpt(body)
      MarkdownPlainText.render(body).squish.truncate(EXCERPT_LENGTH)
    end
  end
end
