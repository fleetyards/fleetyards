# frozen_string_literal: true

module Notifications
  # Tells a fleet that its officers posted something. Run off the request
  # because the audience is the whole fleet, which can be hundreds of members.
  class FleetAnnouncementPostedJob < Notifications::BaseJob
    sidekiq_options retry: 3

    NOTIFICATION_TYPE = :fleet_announcement_posted

    # The partial unique index that makes a retry a no-op.
    RECIPIENT_INDEX = :index_notifications_on_fleet_announcement_recipient

    BATCH_SIZE = 1000

    EXCERPT_LENGTH = 200

    def perform(announcement_id)
      # Taken down or run out before the queue reached it: nothing to tell.
      announcement = FleetAnnouncement.active.find_by(id: announcement_id)
      return if announcement.blank?

      fleet = announcement.fleet
      return if fleet.blank? || fleet.discarded?

      excerpt = MarkdownPlainText.render(announcement.body).squish.truncate(EXCERPT_LENGTH)
      messages = Hash.new { |cache, locale| cache[locale] = message(locale, fleet, announcement, excerpt) }

      fleet.fleet_memberships.kept.accepted
        .where.not(user_id: announcement.author_id)
        .includes(:user)
        .find_in_batches(batch_size: BATCH_SIZE) do |memberships|
          users = memberships.filter_map(&:user)
          notify(users, fleet, announcement, messages) if users.any?
        end
    end

    private def notify(users, fleet, announcement, messages)
      preferences = BulkDelivery.preferences_for(NOTIFICATION_TYPE, users.map(&:id))
      now = Time.zone.now
      expires_at = now + Notification.retention_for(NOTIFICATION_TYPE)

      rows = users.map do |user|
        {
          user_id: user.id,
          notification_type: NOTIFICATION_TYPE.to_s,
          link: "/fleets/#{fleet.slug}/",
          icon: "fa-duotone fa-bullhorn",
          record_type: "FleetAnnouncement",
          record_id: announcement.id,
          read_at: preferences[user.id][:app] ? nil : now,
          expires_at:,
          created_at: now,
          updated_at: now,
          **messages[user.notification_locale]
        }
      end

      notifications = Notification.insert_all(rows, unique_by: RECIPIENT_INDEX, returning: %w[id user_id])

      BulkDelivery.new(notifications, preferences,
        mailer: Notification.mailer_for(NOTIFICATION_TYPE),
        label: "Fleet announcement").deliver
    end

    # In the reader's own language: the title and body are stored, and one fleet
    # reaches members who do not share one.
    private def message(locale, fleet, announcement, excerpt)
      I18n.with_locale(locale) do
        {
          title: I18n.t("notifications.fleet_announcement.posted.title", fleet: fleet.name),
          body: I18n.t("notifications.fleet_announcement.posted.body",
            author: announcement.author&.username || fleet.name, excerpt: excerpt)
        }
      end
    end
  end
end
