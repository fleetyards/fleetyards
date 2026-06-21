# frozen_string_literal: true

require "test_helper"

module Notifications
  class FleetEventStartingSoonJobTest < ActiveJob::TestCase
    setup do
      @fleet = create(:fleet)
    end

    test "notifies one-off events whose start is within the window" do
      event = create(:fleet_event, :open,
        fleet: @fleet, starts_at: 20.minutes.from_now)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        ::Notifications::FleetEventStartingSoonJob.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      assert_equal 1, events.size
      assert_equal event, events.first.payload[:event]
      assert event.reload.starting_soon_notified_at.present?
    end

    test "skips one-off events already notified" do
      create(:fleet_event, :open,
        fleet: @fleet, starts_at: 20.minutes.from_now,
        starting_soon_notified_at: 1.minute.ago)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        ::Notifications::FleetEventStartingSoonJob.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      assert_empty events
    end

    class RecurringEventsTest < FleetEventStartingSoonJobTest
      test "notifies the next occurrence within the window and marks its state" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          starts_at: 20.minutes.from_now)

        events = []
        subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        begin
          ::Notifications::FleetEventStartingSoonJob.new.perform
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        assert_equal 1, events.size
        assert_equal event.starts_at.to_date, events.first.payload[:occurrence_date]
        assert event.fleet_event_occurrence_states.first.starting_soon_notified_at.present?
      end

      test "is idempotent for the same occurrence" do
        event = create(:fleet_event, :open,
          fleet: @fleet,
          recurring: true, recurrence_interval: "weekly",
          starts_at: 20.minutes.from_now)

        ::Notifications::FleetEventStartingSoonJob.new.perform
        first_at = event.fleet_event_occurrence_states.first.starting_soon_notified_at

        ::Notifications::FleetEventStartingSoonJob.new.perform

        assert_equal first_at, event.fleet_event_occurrence_states.first.reload.starting_soon_notified_at
      end
    end
  end
end
