# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_events
#
#  id                        :uuid             not null, primary key
#  archived_at               :datetime
#  auto_lock_enabled         :boolean          default(TRUE), not null
#  auto_lock_minutes_before  :integer          default(60), not null
#  briefing                  :text
#  cancelled_reason          :text
#  category                  :integer          default("other"), not null
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  ends_at                   :datetime
#  excluded_dates            :date             default([]), not null, is an Array
#  external_uid              :uuid             not null
#  location                  :string
#  max_attendees             :integer
#  meetup_location           :string
#  recurrence_count          :integer
#  recurrence_interval       :string
#  recurrence_until          :date
#  recurring                 :boolean          default(FALSE), not null
#  scenario                  :string
#  signup_approval           :string           default("direct"), not null
#  slug                      :string           not null
#  starting_soon_notified_at :datetime
#  starts_at                 :datetime         not null
#  status                    :string           default("draft"), not null
#  timezone                  :string           default("UTC"), not null
#  title                     :string           not null
#  visibility                :string           default("members"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  created_by_id             :uuid             not null
#  discord_event_id          :string
#  discord_message_id        :string
#  fleet_id                  :uuid             not null
#  mission_id                :uuid
#
# Indexes
#
#  index_fleet_events_on_external_uid            (external_uid) UNIQUE
#  index_fleet_events_on_fleet_id_and_recurring  (fleet_id,recurring)
#  index_fleet_events_on_fleet_id_and_slug       (fleet_id,slug) UNIQUE
#  index_fleet_events_on_fleet_id_and_starts_at  (fleet_id,starts_at)
#  index_fleet_events_on_fleet_id_and_status     (fleet_id,status)
#  index_fleet_events_on_mission_id              (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (mission_id => missions.id)
#
require "rails_helper"

RSpec.describe FleetEvent, type: :model do
  describe "#signups_count" do
    let(:event) { create(:fleet_event, :open) }
    let(:team) { create(:fleet_event_team, fleet_event: event) }
    let(:slot) { create(:fleet_event_slot, slottable: team) }
    let(:fleet_membership) { create(:fleet_membership, fleet: event.fleet) }
    let(:other_membership) { create(:fleet_membership, fleet: event.fleet) }

    it "counts slot-bound and unassigned signups together, ignoring withdrawn" do
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership)
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: other_membership, status: "interested")
      withdrawn_member = create(:fleet_membership, fleet: event.fleet)
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: withdrawn_member, status: "withdrawn")

      expect(event.signups_count).to eq(2)
    end
  end

  describe "#past?" do
    it "is true when ends_at is in the past" do
      event = build(:fleet_event, starts_at: 2.hours.ago, ends_at: 1.hour.ago)
      expect(event.past?).to be true
    end

    it "falls back to starts_at when ends_at is nil" do
      event = build(:fleet_event, starts_at: 1.hour.ago, ends_at: nil)
      expect(event.past?).to be true
    end

    it "is false for upcoming events" do
      event = build(:fleet_event, starts_at: 1.day.from_now)
      expect(event.past?).to be false
    end
  end

  describe "#signups_open?" do
    it "is true when status is open and event is not past" do
      event = build(:fleet_event, :open, starts_at: 1.day.from_now)
      expect(event.signups_open?).to be true
    end

    it "is false when status is open but the event already happened" do
      event = build(:fleet_event, :open, starts_at: 2.hours.ago, ends_at: 1.hour.ago)
      expect(event.signups_open?).to be false
    end

    it "is false for non-open statuses" do
      %i[locked active cancelled].each do |trait|
        event = build(:fleet_event, trait, starts_at: 1.day.from_now)
        expect(event.signups_open?).to be(false), "expected #{trait} event to be closed"
      end
    end
  end

  describe "#archive! / #unarchive!" do
    it "round-trips archived_at" do
      event = create(:fleet_event)
      expect(event.archived?).to be false
      event.archive!
      expect(event.reload.archived?).to be true
      event.unarchive!
      expect(event.reload.archived?).to be false
    end
  end

  describe "#occurrences" do
    let(:fleet) { create(:fleet) }
    let(:thursday) { Time.zone.parse("2026-05-14 20:00:00 UTC") }

    it "returns just starts_at for a one-off event within the range" do
      event = create(:fleet_event, fleet: fleet, starts_at: thursday)

      expect(event.occurrences(from: thursday - 1.day, to: thursday + 1.day))
        .to eq([thursday])
    end

    it "returns nothing for a one-off event outside the range" do
      event = create(:fleet_event, fleet: fleet, starts_at: thursday)

      expect(event.occurrences(from: thursday + 1.day, to: thursday + 7.days))
        .to be_empty
    end

    it "expands a weekly recurring event into successive occurrences" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "weekly")

      result = event.occurrences(from: thursday, to: thursday + 4.weeks)

      expect(result.size).to eq(5) # May 14, 21, 28, June 4, 11
      expect(result.map { |t| t.wday }.uniq).to eq([4])
    end

    it "honours biweekly interval" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "biweekly")

      result = event.occurrences(from: thursday, to: thursday + 6.weeks)

      expect(result.size).to eq(4) # 14, 28 May, 11, 25 June
    end

    it "honours daily interval" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "daily")

      result = event.occurrences(from: thursday, to: thursday + 3.days)

      expect(result.size).to eq(4)
    end

    it "honours recurrence_until" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "weekly",
        recurrence_until: Date.parse("2026-05-28"))

      result = event.occurrences(from: thursday, to: thursday + 8.weeks)

      expect(result.size).to eq(3) # 14, 21, 28
    end

    it "honours recurrence_count" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "weekly",
        recurrence_count: 4)

      result = event.occurrences(from: thursday, to: thursday + 8.weeks)

      expect(result.size).to eq(4)
    end

    it "honours excluded_dates" do
      event = create(:fleet_event,
        fleet: fleet, starts_at: thursday,
        recurring: true, recurrence_interval: "weekly",
        excluded_dates: [Date.parse("2026-05-21")])

      result = event.occurrences(from: thursday, to: thursday + 4.weeks)

      expect(result.map(&:to_date)).not_to include(Date.parse("2026-05-21"))
      expect(result.size).to eq(4) # would be 5, minus the excluded one
    end
  end

  describe "#skip_occurrence!" do
    it "appends the date to excluded_dates" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly")

      event.skip_occurrence!(Date.parse("2026-05-21"))

      expect(event.reload.excluded_dates).to include(Date.parse("2026-05-21"))
    end

    it "is idempotent for already-excluded dates" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly",
        excluded_dates: [Date.parse("2026-05-21")])

      expect { event.skip_occurrence!(Date.parse("2026-05-21")) }
        .not_to change { event.reload.excluded_dates.size }
    end
  end

  describe "#end_series_at!" do
    it "sets recurrence_until to the day before the given date" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly")

      event.end_series_at!(Date.parse("2026-06-04"))

      expect(event.reload.recurrence_until).to eq(Date.parse("2026-06-03"))
    end
  end

  describe "validations on recurring fields" do
    it "requires recurrence_interval when recurring" do
      event = build(:fleet_event,
        recurring: true, recurrence_interval: nil)

      expect(event).not_to be_valid
      expect(event.errors[:recurrence_interval]).to be_present
    end

    it "rejects recurrence_interval on non-recurring events" do
      event = build(:fleet_event,
        recurring: false, recurrence_interval: "weekly")

      expect(event).not_to be_valid
      expect(event.errors[:recurrence_interval]).to be_present
    end

    it "rejects both recurrence_count and recurrence_until" do
      event = build(:fleet_event,
        recurring: true, recurrence_interval: "weekly",
        recurrence_count: 4, recurrence_until: Date.tomorrow)

      expect(event).not_to be_valid
    end
  end
end
