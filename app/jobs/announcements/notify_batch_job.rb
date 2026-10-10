# frozen_string_literal: true

module Announcements
  # Writes one batch of readers their notification.
  #
  # Not Notification.notify! per reader: that is a preference SELECT, an INSERT
  # and a broadcast each, which at 57k readers is ~115k round trips.
  class NotifyBatchJob < Announcements::BaseJob
    # The partial unique index that makes a retry a no-op.
    RECIPIENT_INDEX = :index_notifications_on_announcement_recipient

    def perform(announcement_id, user_ids)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?
      return if user_ids.blank?

      preferences = Notifications::BulkDelivery.preferences_for(Announcement::NOTIFICATION_TYPE, user_ids)
      now = Time.zone.now
      expires_at = now + Notification.retention_for(Announcement::NOTIFICATION_TYPE)

      rows = user_ids.map do |user_id|
        preference = preferences[user_id]

        {
          user_id:,
          notification_type: Announcement::NOTIFICATION_TYPE.to_s,
          title: announcement.title,
          body: announcement.body,
          link: announcement.link,
          icon: announcement.icon,
          record_type: "Announcement",
          record_id: announcement.id,
          # A reader who turned the app channel off still gets the row -- the
          # inbox is where an announcement lives -- but it arrives already
          # read, so it does not put a badge on a bell they asked to be quiet.
          read_at: preference[:app] ? nil : now,
          expires_at:,
          created_at: now,
          updated_at: now
        }
      end

      # `unique_by` makes this ON CONFLICT DO NOTHING against the announcement
      # recipient index, and `returning` then names only the rows this run
      # actually wrote. A retry after a partial failure therefore re-inserts
      # nothing and, just as importantly, re-delivers nothing.
      notifications = Notification.insert_all(rows, unique_by: RECIPIENT_INDEX, returning: %w[id user_id])

      Notifications::BulkDelivery.new(notifications, preferences,
        mailer: ->(notification) { AnnouncementMailer.published(notification).deliver_later },
        label: "Announcement").deliver
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
