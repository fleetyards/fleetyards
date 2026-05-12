# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendars::IcsBuilder do
  let(:fleet) { create(:fleet, name: "MARU Inc.") }

  describe "#to_ics" do
    let(:event) do
      create(:fleet_event, :open,
        fleet: fleet,
        title: "Thursday Play Evening",
        description: "Cargo runs",
        starts_at: Time.zone.parse("2026-06-04 20:00:00 UTC"),
        ends_at: Time.zone.parse("2026-06-04 22:00:00 UTC"),
        timezone: "Europe/Berlin",
        location: "Stanton",
        meetup_location: "Levski, Nyx",
        category: "cargo_hauling")
    end

    it "wraps the body in VCALENDAR/VEVENT" do
      ics = described_class.new([event], calendar_name: "#{fleet.name} — Events").to_ics

      expect(ics).to start_with("BEGIN:VCALENDAR\r\n")
      expect(ics).to end_with("END:VCALENDAR\r\n")
      expect(ics).to include("BEGIN:VEVENT")
      expect(ics).to include("END:VEVENT")
      expect(ics).to include("PRODID:-//Fleetyards//Mission Builder//EN")
      expect(ics).to include("X-WR-CALNAME:MARU Inc. — Events")
    end

    it "includes summary, description, location, status, category, url, and uid" do
      ics = described_class.new([event]).to_ics

      expect(ics).to include("SUMMARY:Thursday Play Evening")
      expect(ics).to include("DESCRIPTION:Cargo runs")
      expect(ics).to include("STATUS:CONFIRMED")
      expect(ics).to include("CATEGORIES:CARGO_HAULING")
      expect(ics).to include("UID:#{event.external_uid}@fleetyards.net")
      expect(ics).to include("URL:")
      expect(ics).to include("/fleets/#{fleet.slug}/events/#{event.slug}")
      expect(ics).to include("Stanton")
      expect(ics).to include('Levski\\, Nyx')
    end

    it "uses TZID for non-UTC events and emits a VTIMEZONE block" do
      ics = described_class.new([event]).to_ics

      expect(ics).to include("BEGIN:VTIMEZONE")
      expect(ics).to include("TZID:Europe/Berlin")
      expect(ics).to include("END:VTIMEZONE")
      expect(ics).to include("DTSTART;TZID=Europe/Berlin:20260604T220000")
      expect(ics).to include("DTEND;TZID=Europe/Berlin:20260605T000000")
    end

    it "uses plain UTC stamps when the event timezone is UTC" do
      utc_event = create(:fleet_event, :open,
        fleet: fleet,
        starts_at: Time.zone.parse("2026-06-04 20:00:00 UTC"),
        timezone: "UTC")

      ics = described_class.new([utc_event]).to_ics

      expect(ics).not_to include("BEGIN:VTIMEZONE")
      expect(ics).to include("DTSTART:20260604T200000Z")
    end

    it "emits STATUS:CANCELLED for cancelled events" do
      cancelled = create(:fleet_event, :cancelled, fleet: fleet)

      ics = described_class.new([cancelled]).to_ics

      expect(ics).to include("STATUS:CANCELLED")
    end

    it "sets X-WR-TIMEZONE when every event shares a single non-UTC zone" do
      ics = described_class.new([event]).to_ics

      expect(ics).to include("X-WR-TIMEZONE:Europe/Berlin")
    end

    it "omits X-WR-TIMEZONE when events span multiple zones" do
      other = create(:fleet_event, :open, fleet: fleet, timezone: "America/New_York")

      ics = described_class.new([event, other]).to_ics

      expect(ics).not_to match(/X-WR-TIMEZONE:/)
    end

    it "escapes commas and semicolons in user content" do
      tricky = create(:fleet_event, :open,
        fleet: fleet,
        title: "Cargo; runs, fun",
        location: "Levski; Nyx, Stanton")

      ics = described_class.new([tricky]).to_ics

      expect(ics).to include('SUMMARY:Cargo\\; runs\\, fun')
      expect(ics).to include('Levski\\; Nyx\\, Stanton')
    end
  end
end
