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
          .with(@event.id, "upsert")

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.published", {event: @event}).call
      end

      test "enqueues a delete job on archived/destroyed events" do
        ::Discord::SyncFleetEventJob.expects(:perform_async)
          .with(@event.id, "delete")

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.archived", {event: @event}, action: :delete).call
      end

      # The tests above mock perform_async, which is exactly how the arguments
      # drifted out of step with the job: a trailing hash bound to nothing and
      # every enqueued sync raised ArgumentError. This one runs the real job
      # with whatever the subscriber actually sends.
      test "the arguments the subscriber sends can drive the job" do
        enqueued = nil
        ::Discord::SyncFleetEventJob.stubs(:perform_async).with { |*args|
          enqueued = args
          true
        }
        ::Notifications::Discord::FleetEventSubscriber
          .new("fleet_event.archived", {event: @event}, action: :delete).call

        assert_equal [@event.id, "delete"], enqueued

        sync = mock
        sync.expects(:runnable?).returns(true)
        sync.expects(:delete!)
        ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(sync)

        ::Discord::SyncFleetEventJob.new.perform(*enqueued)
      end

      test "re-pushes the event when it is unarchived" do
        ::Discord::SyncFleetEventJob.expects(:perform_async).with(@event.id, "upsert")

        ::Notifications::Discord::FleetEventSubscriber
          .new("fleet_event.unarchived", {event: @event}).call
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
