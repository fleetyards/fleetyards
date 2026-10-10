# frozen_string_literal: true

module Notifications
  # Tells a fleet that its officers posted something. Run off the request
  # because the audience is the whole fleet, which can be hundreds of members.
  class FleetAnnouncementPostedJob < Notifications::BaseJob
    sidekiq_options retry: 3

    EXCERPT_LENGTH = 200

    def perform(announcement_id)
      # Taken down or run out before the queue reached it: nothing to tell.
      announcement = FleetAnnouncement.active.find_by(id: announcement_id)
      return if announcement.blank?

      fleet = announcement.fleet
      return if fleet.blank? || fleet.discarded?

      excerpt = MarkdownPlainText.render(announcement.body).squish.truncate(EXCERPT_LENGTH)

      # A retry picks up where the last run stopped rather than telling the
      # members it already reached a second time.
      told = Notification.where(record: announcement, notification_type: :fleet_announcement_posted)
        .pluck(:user_id).to_set

      fleet.fleet_memberships.kept.accepted.includes(:user).find_each do |membership|
        user = membership.user
        next if user.blank? || user.id == announcement.author_id || told.include?(user.id)

        notify(user, fleet, announcement, excerpt)
      rescue => e
        Rails.logger.error("[FleetAnnouncementPostedJob] #{user&.id} not notified: #{e.class}: #{e.message}")
      end
    end

    # In the reader's own language: the title and body are stored, and one fleet
    # reaches members who do not share one.
    private def notify(user, fleet, announcement, excerpt)
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user: user,
          type: :fleet_announcement_posted,
          title: I18n.t("notifications.fleet_announcement.posted.title", fleet: fleet.name),
          body: I18n.t("notifications.fleet_announcement.posted.body",
            author: announcement.author&.username || fleet.name, excerpt: excerpt),
          link: "/fleets/#{fleet.slug}/",
          icon: "fa-duotone fa-bullhorn",
          record: announcement
        )
      end
    end
  end
end
