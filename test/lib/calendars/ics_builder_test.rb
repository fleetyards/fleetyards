# frozen_string_literal: true

require "test_helper"

module Calendars
  class IcsBuilderTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet, name: "MARU Inc.")
    end

    class ToIcsTest < IcsBuilderTest
      setup do
        @event = create(:fleet_event, :open,
          fleet: @fleet,
          title: "Thursday Play Evening",
          description: "Cargo runs",
          starts_at: Time.zone.parse("2026-06-04 20:00:00 UTC"),
          ends_at: Time.zone.parse("2026-06-04 22:00:00 UTC"),
          timezone: "Europe/Berlin",
          location: "Stanton",
          meetup_location: "Levski, Nyx",
          category: "cargo_hauling")
      end

      test "wraps the body in VCALENDAR/VEVENT" do
        ics = ::Calendars::IcsBuilder.new([@event], calendar_name: "#{@fleet.name} — Events").to_ics

        assert ics.start_with?("BEGIN:VCALENDAR\r\n")
        assert ics.end_with?("END:VCALENDAR\r\n")
        assert_includes ics, "BEGIN:VEVENT"
        assert_includes ics, "END:VEVENT"
        assert_includes ics, "PRODID:-//Fleetyards//Mission Builder//EN"
        assert_includes ics, "X-WR-CALNAME:MARU Inc. — Events"
      end

      test "includes summary, description, location, status, category, url, and uid" do
        ics = ::Calendars::IcsBuilder.new([@event]).to_ics

        assert_includes ics, "SUMMARY:Thursday Play Evening"
        assert_includes ics, "DESCRIPTION:Cargo runs"
        assert_includes ics, "STATUS:CONFIRMED"
        assert_includes ics, "CATEGORIES:CARGO_HAULING"
        assert_includes ics, "UID:#{@event.external_uid}@fleetyards.net"
        assert_includes ics, "URL:"
        assert_includes ics, "/fleets/#{@fleet.slug}/events/#{@event.slug}"
        assert_includes ics, "Stanton"
        assert_includes ics, 'Levski\\, Nyx'
      end

      test "uses TZID for non-UTC events and emits a VTIMEZONE block" do
        ics = ::Calendars::IcsBuilder.new([@event]).to_ics

        assert_includes ics, "BEGIN:VTIMEZONE"
        assert_includes ics, "TZID:Europe/Berlin"
        assert_includes ics, "END:VTIMEZONE"
        assert_includes ics, "DTSTART;TZID=Europe/Berlin:20260604T220000"
        assert_includes ics, "DTEND;TZID=Europe/Berlin:20260605T000000"
      end

      test "uses plain UTC stamps when the event timezone is UTC" do
        utc_event = create(:fleet_event, :open,
          fleet: @fleet,
          starts_at: Time.zone.parse("2026-06-04 20:00:00 UTC"),
          timezone: "UTC")

        ics = ::Calendars::IcsBuilder.new([utc_event]).to_ics

        refute_includes ics, "BEGIN:VTIMEZONE"
        assert_includes ics, "DTSTART:20260604T200000Z"
      end

      test "emits STATUS:CANCELLED for cancelled events" do
        cancelled = create(:fleet_event, :cancelled, fleet: @fleet)

        ics = ::Calendars::IcsBuilder.new([cancelled]).to_ics

        assert_includes ics, "STATUS:CANCELLED"
      end

      test "sets X-WR-TIMEZONE when every event shares a single non-UTC zone" do
        ics = ::Calendars::IcsBuilder.new([@event]).to_ics

        assert_includes ics, "X-WR-TIMEZONE:Europe/Berlin"
      end

      test "omits X-WR-TIMEZONE when events span multiple zones" do
        other = create(:fleet_event, :open, fleet: @fleet, timezone: "America/New_York")

        ics = ::Calendars::IcsBuilder.new([@event, other]).to_ics

        refute_match(/X-WR-TIMEZONE:/, ics)
      end

      test "escapes commas and semicolons in user content" do
        tricky = create(:fleet_event, :open,
          fleet: @fleet,
          title: "Cargo; runs, fun",
          location: "Levski; Nyx, Stanton")

        ics = ::Calendars::IcsBuilder.new([tricky]).to_ics

        assert_includes ics, 'SUMMARY:Cargo\\; runs\\, fun'
        assert_includes ics, 'Levski\\; Nyx\\, Stanton'
      end

      class RecurringEventsTest < ToIcsTest
        setup do
          @thursday = Time.zone.parse("2026-05-14 20:00:00 UTC")
        end

        test "emits RRULE for a weekly recurring event" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "weekly")

          ics = ::Calendars::IcsBuilder.new([event]).to_ics

          assert_includes ics, "RRULE:FREQ=WEEKLY"
        end

        test "emits FREQ=WEEKLY;INTERVAL=2 for biweekly" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "biweekly")

          assert_includes ::Calendars::IcsBuilder.new([event]).to_ics, "RRULE:FREQ=WEEKLY;INTERVAL=2"
        end

        test "emits FREQ=DAILY for daily" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "daily")

          assert_includes ::Calendars::IcsBuilder.new([event]).to_ics, "RRULE:FREQ=DAILY"
        end

        test "emits UNTIL when recurrence_until is set" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "weekly",
            recurrence_until: Date.parse("2026-06-04"))

          assert_includes ::Calendars::IcsBuilder.new([event]).to_ics, "UNTIL=20260604T235959Z"
        end

        test "emits COUNT when recurrence_count is set" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "weekly",
            recurrence_count: 4)

          assert_includes ::Calendars::IcsBuilder.new([event]).to_ics, "COUNT=4"
        end

        test "emits EXDATE lines for excluded dates" do
          event = create(:fleet_event, :open,
            fleet: @fleet, starts_at: @thursday, timezone: "UTC",
            recurring: true, recurrence_interval: "weekly",
            excluded_dates: [Date.parse("2026-05-21")])

          assert_includes ::Calendars::IcsBuilder.new([event]).to_ics, "EXDATE:20260521T200000Z"
        end
      end
    end
  end
end
