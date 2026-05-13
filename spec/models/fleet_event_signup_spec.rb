# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_signups
#
#  id                  :uuid             not null, primary key
#  confirmed_at        :datetime
#  notes               :text
#  occurrence_date     :date
#  status              :string           default("confirmed"), not null
#  withdrawn_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_event_id      :uuid             not null
#  fleet_event_slot_id :uuid
#  fleet_membership_id :uuid             not null
#  vehicle_id          :uuid
#
# Indexes
#
#  idx_fleet_event_signups_on_event_and_occurrence_and_member  (fleet_event_id,occurrence_date,fleet_membership_id)
#  index_fleet_event_signups_on_fleet_event_id                 (fleet_event_id)
#  index_fleet_event_signups_on_fleet_event_slot_id            (fleet_event_slot_id)
#  index_fleet_event_signups_on_fleet_membership_id            (fleet_membership_id)
#  index_fleet_event_signups_unique_active_per_event           (fleet_event_id,occurrence_date,fleet_membership_id) UNIQUE WHERE ((status)::text <> 'withdrawn'::text)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#  fk_rails_...  (fleet_event_slot_id => fleet_event_slots.id)
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => nullify
#
require "rails_helper"

RSpec.describe FleetEventSignup, type: :model do
  let(:event) { create(:fleet_event, :open) }
  let(:team) { create(:fleet_event_team, fleet_event: event) }
  let(:slot) { create(:fleet_event_slot, slottable: team) }
  let(:fleet_membership) { create(:fleet_membership, fleet: event.fleet) }

  describe "slot_bound_status_allowed validation" do
    it "accepts confirmed signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "confirmed")
      expect(signup).to be_valid
    end

    it "accepts pending signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "pending")
      expect(signup).to be_valid
    end

    it "rejects tentative signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "tentative")
      expect(signup).not_to be_valid
      expect(signup.errors.details[:status]).to include(error: :invalid_for_slot)
    end

    it "rejects interested signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "interested")
      expect(signup).not_to be_valid
    end

    it "allows tentative signups when there is no slot" do
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: fleet_membership, status: "tentative")
      expect(signup).to be_valid
    end
  end

  describe "unique_active_signup_per_member" do
    it "rejects a second active signup for the same member on the same event" do
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "confirmed")
      other_slot = create(:fleet_event_slot, slottable: team)
      duplicate = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: other_slot, fleet_membership: fleet_membership, status: "confirmed")
      expect(duplicate).not_to be_valid
    end

    it "allows another signup once the first is withdrawn" do
      first = create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "confirmed")
      first.withdraw!
      other_slot = create(:fleet_event_slot, slottable: team)
      duplicate = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: other_slot, fleet_membership: fleet_membership, status: "confirmed")
      expect(duplicate).to be_valid
    end
  end

  describe "slot_not_already_taken" do
    it "rejects a second signup on a slot that already has someone" do
      first_member = create(:fleet_membership, fleet: event.fleet)
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: first_member, status: "confirmed")

      other = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership, status: "confirmed")
      expect(other).not_to be_valid
    end
  end

  describe "#effective_signup_approval" do
    it "uses the slot override when present" do
      slot.update!(signup_approval: "confirmation_required")
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership)
      expect(signup.effective_signup_approval).to eq("confirmation_required")
    end

    it "falls back to the event default when the slot has none" do
      event.update!(signup_approval: "confirmation_required")
      signup = build(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: fleet_membership)
      expect(signup.effective_signup_approval).to eq("confirmation_required")
    end
  end
end
