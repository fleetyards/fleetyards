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
        @fleet.fleet_notification_setting.update!(discord_webhook_url: nil, discord_guild_id: nil)
        ::Discord::SyncFleetEventJob.expects(:perform_async).never

        ::Notifications::Discord::FleetEventSubscriber.new("fleet_event.published", {event: @event}).call
      end

      # A reminder goes to the fleet's webhook, which is a different transport
      # from the scheduled-event sync: no bot token and no guild binding.
      class RemindersTest < FleetEventSubscriberTest
        setup do
          @fleet.fleet_notification_setting.update!(
            discord_webhook_url: "https://discord.com/api/webhooks/1/token"
          )
        end

        def notify(payload)
          ::Notifications::Discord::FleetEventSubscriber
            .new("fleet_event.starting_soon", payload, action: :remind).call
        end

        test "enqueues a reminder when the event is starting soon" do
          ::Discord::AnnounceEventReminderJob.expects(:perform_async).with(@event.id, nil)

          notify({event: @event})
        end

        test "passes the occurrence date through for a recurring event" do
          date = 3.days.from_now.to_date
          ::Discord::AnnounceEventReminderJob.expects(:perform_async).with(@event.id, date.to_s)

          notify({event: @event, occurrence_date: date})
        end

        # Same failure mode the sync had once: mocked arguments that no longer
        # fit the job's signature.
        test "the reminder arguments the subscriber sends can drive the job" do
          enqueued = nil
          ::Discord::AnnounceEventReminderJob.stubs(:perform_async).with { |*args|
            enqueued = args
            true
          }

          notify({event: @event, occurrence_date: 3.days.from_now.to_date})

          reminder = mock
          reminder.expects(:run)
          ::Discord::EventReminder.expects(:new).returns(reminder)

          ::Discord::AnnounceEventReminderJob.new.perform(*enqueued)
        end

        test "sends no reminder when the fleet has no webhook" do
          @fleet.fleet_notification_setting.update!(discord_webhook_url: nil)
          ::Discord::AnnounceEventReminderJob.expects(:perform_async).never

          notify({event: @event})
        end

        # The reminder needs neither, unlike the scheduled-event sync.
        test "sends a reminder without a bot token or a guild binding" do
          ::Discord::ApiClient.stubs(:configured?).returns(false)
          @fleet.fleet_notification_setting.update!(discord_guild_id: nil)
          ::Discord::AnnounceEventReminderJob.expects(:perform_async).with(@event.id, nil)

          notify({event: @event})
        end

        test "does not sync the scheduled event as a side effect" do
          ::Discord::SyncFleetEventJob.expects(:perform_async).never
          ::Discord::AnnounceEventReminderJob.stubs(:perform_async)

          notify({event: @event})
        end
      end
    end
  end
end
