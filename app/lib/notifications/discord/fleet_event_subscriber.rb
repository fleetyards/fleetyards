# frozen_string_literal: true

module Notifications
  module Discord
    class FleetEventSubscriber
      UPSERT_EVENTS = %w[
        fleet_event.published
        fleet_event.locked
        fleet_event.unlocked
        fleet_event.started
        fleet_event.completed
        fleet_event.cancelled
      ].freeze

      DELETE_EVENTS = %w[
        fleet_event.archived
        fleet_event.destroyed
      ].freeze

      def self.register!
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
        return unless ::Discord::ApiClient.configured?
        return if event.fleet.fleet_notification_setting&.discord_guild_id.blank?

        ::Discord::SyncFleetEventJob.perform_async(event.id, "action" => @action.to_s)
      end
    end
  end
end
