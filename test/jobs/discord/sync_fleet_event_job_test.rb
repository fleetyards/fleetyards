# frozen_string_literal: true

require "test_helper"

module Discord
  class SyncFleetEventJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
      @event = create(:fleet_event, :open, fleet: @fleet)
    end

    test "an upsert queued before an archive does not recreate the event" do
      @event.update!(archived_at: Time.current)
      ::Discord::ScheduledEventSync.expects(:new).never

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "upsert")
    end

    test "a delete still runs for an archived event" do
      @event.update!(archived_at: Time.current)
      sync = mock
      sync.expects(:runnable?).returns(true)
      sync.expects(:delete!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(sync)

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "delete")
    end

    test "an upsert runs for a live event" do
      sync = mock
      sync.expects(:runnable?).returns(true)
      sync.expects(:upsert!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(sync)

      ::Discord::SyncFleetEventJob.new.perform(@event.id)
    end
  end
end
