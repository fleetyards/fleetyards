# frozen_string_literal: true

require "test_helper"

module FleetEvents
  class AutoLockJobTest < ActiveJob::TestCase
    setup do
      @fleet = create(:fleet)
    end

    test "locks open events whose auto-lock window has begun" do
      event = create(:fleet_event, :open,
        fleet: @fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 30.minutes.from_now)

      ::FleetEvents::AutoLockJob.new.perform

      assert_equal "locked", event.reload.status
    end

    test "leaves open events whose window hasn't started yet" do
      event = create(:fleet_event, :open,
        fleet: @fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 3.hours.from_now)

      ::FleetEvents::AutoLockJob.new.perform

      assert_equal "open", event.reload.status
    end

    test "skips events with auto-lock disabled" do
      event = create(:fleet_event, :open,
        fleet: @fleet,
        auto_lock_enabled: false,
        auto_lock_minutes_before: 60,
        starts_at: 10.minutes.from_now)

      ::FleetEvents::AutoLockJob.new.perform

      assert_equal "open", event.reload.status
    end

    test "skips events not in the open state" do
      locked = create(:fleet_event, :locked,
        fleet: @fleet,
        auto_lock_enabled: true,
        starts_at: 5.minutes.from_now)
      active = create(:fleet_event, :active,
        fleet: @fleet,
        auto_lock_enabled: true,
        starts_at: 5.minutes.ago)

      before = [locked.reload.status, active.reload.status]
      ::FleetEvents::AutoLockJob.new.perform
      after = [locked.reload.status, active.reload.status]
      assert_equal before, after
    end

    test "still locks events whose start time has already passed" do
      event = create(:fleet_event, :open,
        fleet: @fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 10.minutes.ago)

      ::FleetEvents::AutoLockJob.new.perform

      assert_equal "locked", event.reload.status
    end

    test "fires the fleet_event.locked notification for each locked event" do
      event = create(:fleet_event, :open,
        fleet: @fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 5.minutes.from_now)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.locked") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        ::FleetEvents::AutoLockJob.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      assert_equal 1, events.size
      assert_equal event, events.first.payload[:event]
    end

    class RecurringEventsTest < AutoLockJobTest
      test "locks the next occurrence within the auto-lock window" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          auto_lock_enabled: true, auto_lock_minutes_before: 60,
          starts_at: 30.minutes.from_now)

        ::FleetEvents::AutoLockJob.new.perform

        state = event.fleet_event_occurrence_states.first
        assert state.present?
        assert_equal event.starts_at.to_date, state.occurrence_date
        assert state.locked_at.present?
      end

      test "is idempotent — re-running doesn't re-lock the same occurrence" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          auto_lock_enabled: true, auto_lock_minutes_before: 60,
          starts_at: 30.minutes.from_now)

        ::FleetEvents::AutoLockJob.new.perform
        first_locked_at = event.fleet_event_occurrence_states.first.locked_at

        ::FleetEvents::AutoLockJob.new.perform

        assert_equal first_locked_at, event.fleet_event_occurrence_states.first.reload.locked_at
      end

      test "doesn't lock occurrences whose window hasn't begun" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          auto_lock_enabled: true, auto_lock_minutes_before: 60,
          starts_at: 3.hours.from_now)

        ::FleetEvents::AutoLockJob.new.perform

        assert_empty event.fleet_event_occurrence_states
      end

      test "skips cancelled occurrences" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          auto_lock_enabled: true, auto_lock_minutes_before: 60,
          starts_at: 30.minutes.from_now)
        create(:fleet_event_occurrence_state,
          fleet_event: event, occurrence_date: event.starts_at.to_date,
          cancelled_at: Time.current)

        ::FleetEvents::AutoLockJob.new.perform

        assert_nil event.fleet_event_occurrence_states.first.locked_at
      end
    end
  end
end
