# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetEventOccurrenceState, type: :model do
  let(:event) do
    create(:fleet_event, :open,
      title: "Thursday Play Evening",
      location: "Stanton",
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      recurring: true, recurrence_interval: "weekly")
  end

  describe "uniqueness" do
    it "enforces one row per (event, occurrence_date)" do
      create(:fleet_event_occurrence_state,
        fleet_event: event, occurrence_date: Date.parse("2026-05-14"))

      dup = build(:fleet_event_occurrence_state,
        fleet_event: event, occurrence_date: Date.parse("2026-05-14"))

      expect(dup).not_to be_valid
    end
  end

  describe "#effective" do
    it "returns the override when set" do
      state = create(:fleet_event_occurrence_state,
        fleet_event: event, occurrence_date: Date.parse("2026-05-21"),
        location: "Levski")

      expect(state.effective(:location)).to eq("Levski")
    end

    it "falls back to the event's value when nil" do
      state = create(:fleet_event_occurrence_state,
        fleet_event: event, occurrence_date: Date.parse("2026-05-21"))

      expect(state.effective(:location)).to eq("Stanton")
      expect(state.effective(:title)).to eq("Thursday Play Evening")
    end
  end

  describe "FleetEvent#occurrence_state_for" do
    it "returns nil for an unknown date by default" do
      expect(event.occurrence_state_for(Date.parse("2026-05-21"))).to be_nil
    end

    it "builds a new state when build: true" do
      state = event.occurrence_state_for(Date.parse("2026-05-21"), build: true)

      expect(state).to be_present
      expect(state).to be_new_record
      expect(state.occurrence_date).to eq(Date.parse("2026-05-21"))
    end

    it "returns the existing state if present" do
      existing = create(:fleet_event_occurrence_state,
        fleet_event: event, occurrence_date: Date.parse("2026-05-21"),
        location: "Levski")

      result = event.occurrence_state_for(Date.parse("2026-05-21"))

      expect(result).to eq(existing)
    end
  end
end
