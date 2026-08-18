# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_event_occurrence_states
#
#  id                        :uuid             not null, primary key
#  briefing                  :text
#  cancelled_at              :datetime
#  cancelled_reason          :text
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  location                  :string
#  locked_at                 :datetime
#  meetup_location           :string
#  occurrence_date           :date             not null
#  scenario                  :string
#  starting_soon_notified_at :datetime
#  status                    :string
#  title                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  discord_event_id          :string
#  fleet_event_id            :uuid             not null
#
# Indexes
#
#  idx_fleet_event_occurrence_states_on_event_and_date  (fleet_event_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#
class FleetEventOccurrenceStateTest < ActiveSupport::TestCase
  setup do
    @event = create(:fleet_event, :open,
      title: "Thursday Play Evening",
      location: "Stanton",
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      recurring: true, recurrence_interval: "weekly")
  end

  class UniquenessTest < FleetEventOccurrenceStateTest
    test "enforces one row per (event, occurrence_date)" do
      create(:fleet_event_occurrence_state,
        fleet_event: @event, occurrence_date: Date.parse("2026-05-14"))

      dup = build(:fleet_event_occurrence_state,
        fleet_event: @event, occurrence_date: Date.parse("2026-05-14"))

      refute dup.valid?
    end
  end

  class EffectiveTest < FleetEventOccurrenceStateTest
    test "returns the override when set" do
      state = create(:fleet_event_occurrence_state,
        fleet_event: @event, occurrence_date: Date.parse("2026-05-21"),
        location: "Levski")

      assert_equal "Levski", state.effective(:location)
    end

    test "falls back to the event's value when nil" do
      state = create(:fleet_event_occurrence_state,
        fleet_event: @event, occurrence_date: Date.parse("2026-05-21"))

      assert_equal "Stanton", state.effective(:location)
      assert_equal "Thursday Play Evening", state.effective(:title)
    end
  end

  class FleetEventOccurrenceStateForTest < FleetEventOccurrenceStateTest
    test "returns nil for an unknown date by default" do
      assert_nil @event.occurrence_state_for(Date.parse("2026-05-21"))
    end

    test "builds a new state when build: true" do
      state = @event.occurrence_state_for(Date.parse("2026-05-21"), build: true)

      assert state.present?
      assert state.new_record?
      assert_equal Date.parse("2026-05-21"), state.occurrence_date
    end

    test "returns the existing state if present" do
      existing = create(:fleet_event_occurrence_state,
        fleet_event: @event, occurrence_date: Date.parse("2026-05-21"),
        location: "Levski")

      result = @event.occurrence_state_for(Date.parse("2026-05-21"))

      assert_equal existing, result
    end
  end
end
