# frozen_string_literal: true

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
end
