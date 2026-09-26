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

    # A scheduled event is shown to the whole guild, so a squadron's event is
    # taken down rather than posted or updated there.
    test "an upsert of a squadron event deletes it from the guild instead" do
      squadron = create(:fleet_squadron, fleet: @fleet)
      @event.update!(visibility: "squadron", fleet_squadrons: [squadron])
      sync = mock
      sync.expects(:runnable?).returns(true)
      sync.expects(:upsert!).never
      sync.expects(:delete!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(sync)

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "upsert")
    end

    test "an upsert of an officers' event deletes it from the guild instead" do
      @event.update!(visibility: "officers")
      sync = mock
      sync.expects(:runnable?).returns(true)
      sync.expects(:upsert!).never
      sync.expects(:delete!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(sync)

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "upsert")
    end

    # Narrowed and opened up again, the narrowing's delete can arrive last.
    test "a delete does not undo an event opened up again meanwhile" do
      ::Discord::ScheduledEventSync.expects(:new).never

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "delete")
    end

    test "a delete also takes down the scheduled events of a series' occurrences" do
      @event.update!(archived_at: Time.current)
      date = 1.week.from_now.to_date
      @event.fleet_event_occurrence_states.create!(occurrence_date: date, discord_event_id: "occurrence-1")
      series = mock
      series.expects(:runnable?).returns(true)
      series.expects(:delete!)
      occurrence = mock
      occurrence.expects(:delete!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(series)
      ::Discord::ScheduledEventSync.expects(:new).with(@event, occurrence_date: date).returns(occurrence)

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "delete")
    end

    test "an occurrence upsert refreshes only the occurrences already pushed" do
      pushed = 1.week.from_now.to_date
      @event.fleet_event_occurrence_states.create!(occurrence_date: pushed, discord_event_id: "occurrence-1")
      @event.fleet_event_occurrence_states.create!(occurrence_date: pushed + 7, title: "Not pushed")
      series = mock
      series.expects(:runnable?).returns(true)
      series.expects(:upsert!).never
      occurrence = mock
      occurrence.expects(:upsert!)
      ::Discord::ScheduledEventSync.expects(:new).with(@event).returns(series)
      ::Discord::ScheduledEventSync.expects(:new).with(@event, occurrence_date: pushed).returns(occurrence)

      ::Discord::SyncFleetEventJob.new.perform(@event.id, "upsert_occurrences")
    end
  end
end
