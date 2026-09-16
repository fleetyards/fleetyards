# frozen_string_literal: true

module Announcements
  # Writes one batch of readers their notification.
  #
  # Not Notification.notify! per reader: that is a preference SELECT, an INSERT
  # and a broadcast each, which at 57k readers is ~115k round trips. This loads
  # the batch's preferences in one query and inserts in one statement.
  class NotifyBatchJob < Announcements::BaseJob
    # How recently a reader has to have been here for a live push to reach a
    # tab that is still open.
    BROADCAST_WINDOW = 15.minutes

    # The partial unique index that makes a retry a no-op.
    RECIPIENT_INDEX = :index_notifications_on_announcement_recipient

    def perform(announcement_id, user_ids)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?
      return if user_ids.blank?

      preferences = preferences_for(user_ids)
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

      deliver(notifications, preferences)
      settle(announcement)
    end

    # Existing accounts have no row for a type added after they signed up --
    # the defaults are written in an after_create hook -- so a miss is the
    # normal case here, not an error.
    private def preferences_for(user_ids)
      defaults = Notification.preference_defaults_for(Announcement::NOTIFICATION_TYPE)

      stored = NotificationPreference
        .where(user_id: user_ids, notification_type: Announcement::NOTIFICATION_TYPE)
        .pluck(:user_id, :app, :mail)
        .to_h { |user_id, app, mail| [user_id, {app:, mail:}] }

      user_ids.index_with { |user_id| stored[user_id] || {app: defaults[:app], mail: defaults[:mail]} }
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

    private def deliver(notifications, preferences)
      app_user_ids = preferences.select { |_id, channels| channels[:app] }.keys
      mail_user_ids = preferences.select { |_id, channels| channels[:mail] }.keys

      broadcast(notifications, app_user_ids)
      mail(notifications, mail_user_ids)
    end

    # Only readers who were using the site in the last few minutes. A broadcast
    # is worth something to an open tab and nothing to anybody else -- whoever
    # is not here loads the notification from the API on their next visit, the
    # same as for every notification written while they were away.
    #
    # The cost this avoids is not the publish, it is `to_jbuilder_hash`: it
    # renders the notification through ActionController::Renderer, so an
    # unfiltered fan-out is ~57k template renders for an audience of a few
    # hundred.
    private def broadcast(notifications, user_ids)
      return if user_ids.empty?

      active_ids = User.where(id: user_ids)
        .where(last_active_at: BROADCAST_WINDOW.ago..)
        .pluck(:id)
      return if active_ids.empty?

      ids = notification_ids(notifications, active_ids)

      Notification.where(id: ids).includes(:user).find_each do |notification|
        UserNotificationsChannel.broadcast_to(notification.user, notification.to_jbuilder_hash)
      rescue => e
        Rails.logger.error("Announcement broadcast failed for #{notification.id}: #{e.message}")
      end
    end

    private def mail(notifications, user_ids)
      return if user_ids.empty?

      Notification.where(id: notification_ids(notifications, user_ids)).find_each do |notification|
        AnnouncementMailer.published(notification).deliver_later
      end
    end

    private def notification_ids(notifications, user_ids)
      wanted = user_ids.to_set

      notifications.rows.filter_map { |id, user_id| id if wanted.include?(user_id) }
    end
  end
end
