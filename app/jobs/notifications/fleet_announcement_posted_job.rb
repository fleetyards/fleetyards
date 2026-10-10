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
          users = memberships.filter_map(&:user)
          next if users.empty?

          delivery = write(users, fleet, announcement, messages)
          break if delivery.nil?

          delivery.deliver
        end
    end

    private def batch_size = BATCH_SIZE

    # Under a share lock on the announcement, which taking it down waits for:
    # a batch written first is withdrawn with the rest, and a batch after the
    # takedown finds it gone. Nil once there is nothing to tell -- taken down,
    # run out or the fleet closed while the fleet was being told.
    #
    # Delivered only after the commit: the push and Discord jobs look the rows
    # up, and could otherwise run before they exist.
    private def write(users, fleet, announcement, messages)
      locales = users.to_h { |user| [user.id, user.notification_locale] }

      FleetAnnouncement.transaction do
        next unless FleetAnnouncement.active.lock("FOR SHARE").exists?(id: announcement.id)
        next unless Fleet.kept.exists?(id: fleet.id)

        BulkDelivery.write(
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
