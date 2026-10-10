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
        .find_in_batches(batch_size:) do |memberships|
          # Taken down while the fleet was being told: deleting it withdrew the
          # rows written so far, and later batches must not write more.
          break unless FleetAnnouncement.exists?(announcement.id)

          users = memberships.filter_map(&:user)
          notify(users, fleet, announcement, messages) if users.any?
        end
    end

    private def batch_size = BATCH_SIZE

    private def notify(users, fleet, announcement, messages)
      locales = users.to_h { |user| [user.id, user.notification_locale] }

      BulkDelivery.notify(
        type: NOTIFICATION_TYPE,
        user_ids: locales.keys,
        unique_by: RECIPIENT_INDEX,
        mailer: Notification.mailer_for(NOTIFICATION_TYPE),
        label: "Fleet announcement"
      ) do |user_id|
        {
          link: "/fleets/#{fleet.slug}/",
          icon: "fa-duotone fa-bullhorn",
          record_type: "FleetAnnouncement",
          record_id: announcement.id,
          **messages[locales[user_id]]
        }
      end
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
