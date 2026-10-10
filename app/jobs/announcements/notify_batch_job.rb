# frozen_string_literal: true

module Announcements
  # Writes one batch of readers their notification.
  #
  # In bulk rather than Notification.notify! per reader, which at 57k readers
  # is ~115k round trips.
  class NotifyBatchJob < Announcements::BaseJob
    # The partial unique index that makes a retry a no-op.
    RECIPIENT_INDEX = :index_notifications_on_announcement_recipient

    def perform(announcement_id, user_ids)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?
      return if user_ids.blank?

      # `unique_by` makes the insert ON CONFLICT DO NOTHING against the
      # announcement recipient index, so a retry after a partial failure
      # re-inserts nothing and, just as importantly, re-delivers nothing.
      Notifications::BulkDelivery.notify(
        type: Announcement::NOTIFICATION_TYPE,
        user_ids:,
        unique_by: RECIPIENT_INDEX,
        mailer: ->(notification) { AnnouncementMailer.published(notification).deliver_later },
        label: "Announcement"
      ) do
        {
          title: announcement.title,
          body: announcement.body,
          link: announcement.link,
          icon: announcement.icon,
          record_type: "Announcement",
          record_id: announcement.id
        }
      end

      settle(announcement)
    end

    # The in-app delivery is done when every reader has a row, which each batch
    # checks for itself rather than a counter tracking it. A count is the same
    # answer however many times a batch runs; a counter a retried batch bumps
    # twice would call the fan-out finished while a thousand readers still had
    # nothing.
    private def settle(announcement)
      expected = announcement.recipients_count
      return if expected.blank?

      written = Notification.where(record_type: "Announcement", record_id: announcement.id).count
      return if written < expected

      delivery = announcement.delivery_for(AnnouncementDelivery::IN_APP_CHANNEL)
      return if delivery.status_succeeded?

      delivery.succeed!
    rescue ActiveRecord::RecordNotUnique
      # Two batches finished at the same moment and both went to write the row.
      # The other one got there first, which is the answer this wanted anyway.
      nil
    end
  end
end
