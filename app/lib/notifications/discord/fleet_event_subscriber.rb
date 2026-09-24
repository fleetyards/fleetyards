# frozen_string_literal: true

module Notifications
  module Discord
    class FleetEventSubscriber
      UPSERT_EVENTS = %w[
        fleet_event.published
        fleet_event.unarchived
        fleet_event.locked
        fleet_event.unlocked
        fleet_event.started
        fleet_event.completed
        fleet_event.cancelled
      ].freeze

      DELETE_EVENTS = %w[
        fleet_event.archived
        fleet_event.destroyed
        fleet_event.restricted
      ].freeze

      # Not a scheduled-event sync: Discord's own reminder already knows the
      # time, so this posts what it cannot know -- the slots -- to wherever the
      # event may be announced.
      REMINDER_EVENTS = %w[
        fleet_event.starting_soon
      ].freeze

      # A message alongside the scheduled event rather than instead of it: a
      # squadron's event never becomes a scheduled event, so for those this is
      # the only word Discord gets.
      ANNOUNCE_EVENTS = %w[
        fleet_event.published
      ].freeze

      def self.register!
        ANNOUNCE_EVENTS.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload, action: :announce).call
          rescue => e
            Rails.logger.error("[Notifications::Discord::FleetEventSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end

        REMINDER_EVENTS.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload, action: :remind).call
          rescue => e
            Rails.logger.error("[Notifications::Discord::FleetEventSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end

        UPSERT_EVENTS.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload).call
          rescue => e
            Rails.logger.error("[Notifications::Discord::FleetEventSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end

        DELETE_EVENTS.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload, action: :delete).call
          rescue => e
            Rails.logger.error("[Notifications::Discord::FleetEventSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end
      end

      def initialize(event_name, payload, action: :upsert)
        @event_name = event_name
        @payload = payload
        @action = action
      end

      def call
        event = @payload[:event]
        return unless event&.fleet

        return remind(event) if @action == :remind
        return announce(event) if @action == :announce

        return unless ::Discord::ApiClient.configured?
        return if event.fleet.fleet_notification_setting&.discord_guild_id.blank?

        ::Discord::SyncFleetEventJob.perform_async(event.id, @action.to_s)
      end

      # No guild binding needed: a webhook alone is somewhere to post, so a
      # fleet that never installed the bot still gets reminders.
      private def remind(event)
        return unless ::Discord::EventAnnouncement.deliverable?(event)

        ::Discord::AnnounceEventReminderJob.perform_async(
          event.id,
          @payload[:occurrence_date]&.to_s
        )
      end

      private def announce(event)
        return unless ::Discord::EventAnnouncement.deliverable?(event)

        ::Discord::AnnounceEventPublishedJob.perform_async(event.id)
      end
    end
  end
end
