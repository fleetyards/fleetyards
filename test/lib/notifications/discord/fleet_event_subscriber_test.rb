# frozen_string_literal: true

require "test_helper"
require "discord/api_client"

module Notifications
  module Discord
    class FleetEventSubscriberTest < ActiveSupport::TestCase
      setup do
        @fleet = create(:fleet)
        @event = create(:fleet_event, :open, fleet: @fleet)
        @fleet.create_fleet_notification_setting!(discord_guild_id: "123")
        ::Discord::ApiClient.stubs(:configured?).returns(true)
      end

      test "enqueues an upsert job on a publish-class event" do
        ::Discord::SyncFleetEventJob.expects(:perform_async)
          .with(@event.id, "action" => "upsert")

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.published", {event: @event}).call
      end

      test "enqueues a delete job on archived/destroyed events" do
        ::Discord::SyncFleetEventJob.expects(:perform_async)
          .with(@event.id, "action" => "delete")

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.archived", {event: @event}, action: :delete).call
      end

      test "skips silently when the bot token is missing" do
        ::Discord::ApiClient.stubs(:configured?).returns(false)
        ::Discord::SyncFleetEventJob.expects(:perform_async).never

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.published", {event: @event}).call
      end

      test "skips silently when the fleet hasn't connected Discord" do
        @fleet.fleet_notification_setting.update!(discord_guild_id: nil)
        ::Discord::SyncFleetEventJob.expects(:perform_async).never

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.published", {event: @event}).call
      end
    end
  end
end
