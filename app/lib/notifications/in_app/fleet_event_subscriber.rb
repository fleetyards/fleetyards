# frozen_string_literal: true

module Notifications
  module InApp
    class FleetEventSubscriber
      EVENT_NAMES = %w[
        fleet_event.published
        fleet_event.locked
        fleet_event.unlocked
        fleet_event.started
        fleet_event.completed
        fleet_event.cancelled
        fleet_event.starting_soon
        fleet_event_signup.created
        fleet_event_signup.withdrawn
        fleet_event_signup.status_changed
        fleet_event_signup.assigned
      ].freeze

      def self.register!
        EVENT_NAMES.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload).call
          rescue => e
            Rails.logger.error("[FleetEventSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end
      end

      def initialize(event_name, payload)
        @event_name = event_name
        @payload = payload
      end

      def call
        case @event_name
        when "fleet_event.published" then handle_published
        when "fleet_event.locked" then handle_locked
        when "fleet_event.starting_soon" then handle_starting_soon
        when "fleet_event.started" then handle_started
        when "fleet_event.completed" then handle_completed
        when "fleet_event.cancelled" then handle_cancelled
        when "fleet_event_signup.created" then handle_signup_created
        when "fleet_event_signup.withdrawn" then handle_signup_withdrawn
        when "fleet_event_signup.status_changed" then handle_signup_status_changed
        when "fleet_event_signup.assigned" then handle_signup_assigned
        end
      end

      private

      def event
        @payload[:event]
      end

      def signup
        @payload[:signup]
      end

      def setting_for(fleet)
        fleet.fleet_notification_setting ||
          fleet.build_fleet_notification_setting(enabled_in_app_events: FleetNotificationSetting::DEFAULT_IN_APP_EVENTS)
      end

      def in_app_enabled?(fleet, key)
        Array(setting_for(fleet).enabled_in_app_events).include?(key)
      end

      def handle_published
        return unless event && in_app_enabled?(event.fleet, "fleet_event.published")

        eligible_users(event).each do |user|
          notify(user, :fleet_event_published, event,
            title: I18n.t("notifications.fleet_event.published.title", title: event.title),
            body: I18n.t("notifications.fleet_event.published.body", fleet: event.fleet.name))
        end
      end

      def handle_locked
        return unless event && in_app_enabled?(event.fleet, "fleet_event.locked")

        signup_users(event).each do |user|
          notify(user, :fleet_event_locked, event,
            title: I18n.t("notifications.fleet_event.locked.title", title: event.title))
        end
      end

      def handle_starting_soon
        return unless event && in_app_enabled?(event.fleet, "fleet_event.starting_soon")

        signup_users(event).each do |user|
          notify(user, :fleet_event_starting_soon, event,
            title: I18n.t("notifications.fleet_event.starting_soon.title", title: event.title))
        end
      end

      def handle_started
        return unless event

        signup_users(event).each do |user|
          notify(user, :fleet_event_started, event,
            title: I18n.t("notifications.fleet_event.started.title", title: event.title))
        end
      end

      def handle_completed
        return unless event

        signup_users(event).each do |user|
          notify(user, :fleet_event_completed, event,
            title: I18n.t("notifications.fleet_event.completed.title", title: event.title))
        end
      end

      def handle_cancelled
        return unless event && in_app_enabled?(event.fleet, "fleet_event.cancelled")

        signup_users(event).each do |user|
          notify(user, :fleet_event_cancelled, event,
            title: I18n.t("notifications.fleet_event.cancelled.title", title: event.title),
            body: event.cancelled_reason.presence)
        end
      end

      def handle_signup_created
        return unless signup
        target_event = signup.fleet_event
        return unless target_event&.created_by
        return unless in_app_enabled?(target_event.fleet, "fleet_event_signup.created")

        notify(target_event.created_by, :fleet_event_signup_added, target_event,
          title: I18n.t("notifications.fleet_event_signup.added.title",
            user: signup.user&.username || "Member",
            title: target_event.title))
      end

      def handle_signup_withdrawn
        return unless signup
        target_event = signup.fleet_event
        return unless target_event

        # Member-side: notify the affected user when an admin kicked them.
        if @payload[:kicked] && signup.user
          notify(signup.user, :fleet_event_signup_kicked, target_event,
            title: I18n.t("notifications.fleet_event_signup.kicked.title",
              title: target_event.title))
        end

        # Creator-side: same notification regardless of who initiated.
        return unless target_event.created_by
        return unless in_app_enabled?(target_event.fleet, "fleet_event_signup.withdrawn")

        notify(target_event.created_by, :fleet_event_signup_withdrawn, target_event,
          title: I18n.t("notifications.fleet_event_signup.withdrawn.title",
            user: signup.user&.username || "Member",
            title: target_event.title))
      end

      def handle_signup_status_changed
        return unless signup
        target_event = signup.fleet_event
        return unless target_event && signup.user

        # Member-side: notify when an admin promotes pending → confirmed.
        if @payload[:by_admin] && signup.status == "confirmed" && @payload[:previous_status] == "pending"
          notify(signup.user, :fleet_event_signup_confirmed, target_event,
            title: I18n.t("notifications.fleet_event_signup.confirmed.title",
              title: target_event.title))
        end
      end

      def handle_signup_assigned
        return unless signup
        target_event = signup.fleet_event
        return unless target_event && signup.user

        slot_title = signup.fleet_event_slot&.title || target_event.title
        notify(signup.user, :fleet_event_signup_assigned, target_event,
          title: I18n.t("notifications.fleet_event_signup.assigned.title",
            slot: slot_title,
            title: target_event.title))
      end

      def eligible_users(target_event)
        memberships = target_event.fleet.fleet_memberships.where(aasm_state: "accepted").includes(:user, :fleet_role)
        if target_event.visibility == "officers"
          memberships = memberships.select { |m| m.fleet_role&.rank&.in?(%w[admin officer]) }
        end
        memberships.map(&:user).compact
      end

      def signup_users(target_event)
        target_event.fleet_event_signups
          .where.not(status: "withdrawn")
          .includes(:user)
          .map(&:user)
          .compact
          .uniq
      end

      def notify(user, type, target_event, title:, body: nil)
        link = "/fleets/#{target_event.fleet.slug}/events/#{target_event.slug}"
        Notification.notify!(
          user: user,
          type: type,
          title: title,
          body: body,
          link: link,
          icon: "calendar",
          record: target_event
        )
      end
    end
  end
end
