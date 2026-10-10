# frozen_string_literal: true

module Notifications
  # Delivers notifications that were written in bulk with `insert_all`.
  #
  # Not Notification.notify! per reader: that is a preference SELECT, an INSERT
  # and a broadcast each. This loads the batch's preferences in one query, and
  # the caller inserts in one statement. Insert against a unique index with
  # `returning`, so a retry gets back only the rows it actually wrote and
  # therefore delivers nothing twice.
  class BulkDelivery
    # How recently a reader has to have been here for a live push to reach a
    # tab that is still open.
    BROADCAST_WINDOW = 15.minutes

    # Existing accounts have no row for a type added after they signed up --
    # the defaults are written in an after_create hook -- so a miss is the
    # normal case here, not an error.
    def self.preferences_for(type, user_ids)
      defaults = Notification.preference_defaults_for(type).slice(:app, :mail, :push, :discord)

      stored = NotificationPreference
        .where(user_id: user_ids, notification_type: type)
        .pluck(:user_id, :app, :mail, :push, :discord)
        .to_h { |user_id, app, mail, push, discord| [user_id, {app:, mail:, push:, discord:}] }

      user_ids.index_with { |user_id| stored[user_id] || defaults }
    end

    # `notifications` is the `insert_all` result, returning `id` and `user_id`.
    # `mailer` takes a notification and sends its mail.
    def initialize(notifications, preferences, mailer:, label:)
      @notifications = notifications
      @preferences = preferences
      @mailer = mailer
      @label = label
    end

    # Each channel on its own. The rows are already written, so a retry
    # inserts nothing and delivers nothing: a channel that raised here takes
    # every channel after it down for good.
    def deliver
      seen_in_app = deliver_channel(:app) { broadcast(user_ids_for(:app)) } || Set.new
      deliver_channel(:mail) { mail(user_ids_for(:mail)) }
      deliver_channel(:push) { push(user_ids_for(:push), seen_in_app) }
      deliver_channel(:discord) { direct_message(user_ids_for(:discord)) }
    end

    private def user_ids_for(channel)
      @preferences.select { |_id, channels| channels[channel] }.keys
    end

    private def deliver_channel(channel)
      yield
    rescue => e
      Rails.logger.error("#{@label} #{channel} delivery failed: #{e.message}")
      nil
    end

    # Only readers who were using the site in the last few minutes. A broadcast
    # is worth something to an open tab and nothing to anybody else -- whoever
    # is not here loads the notification from the API on their next visit, the
    # same as for every notification written while they were away.
    #
    # The cost this avoids is not the publish, it is `to_jbuilder_hash`: it
    # renders the notification through ActionController::Renderer, so an
    # unfiltered fan-out is a template render per reader for an audience of a
    # few.
    #
    # A tab in use counts too: reading a loaded page makes no API request, and
    # push holds back for exactly those readers on the strength of this toast.
    # Returns them, for the push to skip.
    private def broadcast(user_ids)
      return Set.new if user_ids.empty?

      in_use = UserPresence.active_among(user_ids)
      active_ids = User.where(id: user_ids)
        .where(last_active_at: BROADCAST_WINDOW.ago..)
        .pluck(:id)
        .map(&:to_s) | in_use.to_a
      return Set.new if active_ids.empty?

      Notification.where(id: notification_ids(active_ids)).includes(:user).find_each do |notification|
        UserNotificationsChannel.broadcast_to(notification.user, notification.to_jbuilder_hash)
      rescue => e
        in_use.delete(notification.user_id.to_s)
        Rails.logger.error("#{@label} broadcast failed for #{notification.id}: #{e.message}")
      end

      in_use
    end

    # Enqueued in each reader's locale, which is the one the mail renders in.
    private def mail(user_ids)
      return if user_ids.empty?

      Notification.where(id: notification_ids(user_ids)).includes(:user).find_each do |notification|
        I18n.with_locale(notification.user.notification_locale) do
          @mailer.call(notification)
        end
      end
    end

    private def push(user_ids, seen_in_app)
      return if user_ids.empty?

      wanted = user_ids.to_set
      args = @notifications.rows.filter_map do |id, user_id|
        [id, seen_in_app.include?(user_id.to_s)] if wanted.include?(user_id)
      end
      ::Push::DeliverNotificationJob.perform_bulk(args) if args.any?
    end

    private def direct_message(user_ids)
      return if user_ids.empty?

      ids = notification_ids(user_ids)
      ::Discord::DeliverNotificationJob.perform_bulk(ids.zip) if ids.any?
    end

    private def notification_ids(user_ids)
      wanted = user_ids.to_set

      @notifications.rows.filter_map { |id, user_id| id if wanted.include?(user_id) }
    end
  end
end
