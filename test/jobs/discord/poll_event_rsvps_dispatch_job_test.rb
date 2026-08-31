# frozen_string_literal: true

require "test_helper"

module Discord
  class PollEventRsvpsDispatchJobTest < ActiveSupport::TestCase
    setup do
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      ::Discord::PollEventRsvpsJob.jobs.clear
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    end

    def dispatch
      ::Discord::PollEventRsvpsDispatchJob.new.perform
    end

    def enqueued_event_ids
      ::Discord::PollEventRsvpsJob.jobs.map { |job| job["args"].first }
    end

    test "enqueues a poll for an upcoming synced event" do
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: "scheduled-1")

      dispatch

      assert_equal ["scheduled-1"], enqueued_event_ids
    end

    test "passes the fleet's guild id to the poll" do
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: "scheduled-1")

      dispatch

      assert_equal "guild-1", ::Discord::PollEventRsvpsJob.jobs.first["args"].second
    end

    test "skips an event that was never synced to Discord" do
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: nil)

      dispatch

      assert_empty enqueued_event_ids
    end

    test "skips an archived event" do
      event = create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: "scheduled-1")
      event.update!(archived_at: Time.current)

      dispatch

      assert_empty enqueued_event_ids
    end

    test "skips an event beyond the lookahead" do
      create(:fleet_event, :open, fleet: @fleet,
        starts_at: (::Discord::PollEventRsvpsDispatchJob::LOOKAHEAD + 2.days).from_now,
        discord_event_id: "scheduled-far")

      dispatch

      assert_empty enqueued_event_ids
    end

    # A last-minute RSVP still counts, an event that ended days ago does not.
    test "still polls an event that started within the grace period" do
      create(:fleet_event, :open, fleet: @fleet, starts_at: 30.minutes.ago, discord_event_id: "scheduled-now")

      dispatch

      assert_equal ["scheduled-now"], enqueued_event_ids
    end

    test "skips an event that is long over" do
      create(:fleet_event, :open, fleet: @fleet, starts_at: 3.days.ago, discord_event_id: "scheduled-old")

      dispatch

      assert_empty enqueued_event_ids
    end

    # Recurring occurrences carry their own Discord id on the occurrence state,
    # so polling only FleetEvent would miss all of them.
    test "enqueues a poll for a recurring occurrence" do
      series = create(:fleet_event, :open, fleet: @fleet,
        starts_at: 1.week.from_now, recurring: true, recurrence_interval: "weekly")
      occurrence_date = series.occurrences(from: Time.current, to: 4.weeks.from_now).second.to_date
      series.fleet_event_occurrence_states.create!(
        occurrence_date: occurrence_date, discord_event_id: "scheduled-occurrence-1"
      )

      dispatch

      assert_includes enqueued_event_ids, "scheduled-occurrence-1"
    end

    test "skips a fleet with no Discord guild" do
      @setting.update!(discord_guild_id: nil)
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: "scheduled-1")

      dispatch

      assert_empty enqueued_event_ids
    end

    test "does nothing without a bot token" do
      ::Discord::ApiClient.stubs(:configured?).returns(false)
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, discord_event_id: "scheduled-1")

      dispatch

      assert_empty enqueued_event_ids
    end
  end
end
