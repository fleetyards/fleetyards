# frozen_string_literal: true

require "test_helper"

class FleetEventSignupTest < ActiveSupport::TestCase
  setup do
    @event = create(:fleet_event, :open)
    @team = create(:fleet_event_team, fleet_event: @event)
    @slot = create(:fleet_event_slot, slottable: @team)
    @fleet_membership = create(:fleet_membership, fleet: @event.fleet)
  end

  class SlotBoundStatusAllowedTest < FleetEventSignupTest
    test "accepts confirmed signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")
      assert signup.valid?
    end

    test "accepts pending signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "pending")
      assert signup.valid?
    end

    test "rejects tentative signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "tentative")
      refute signup.valid?
      assert_includes signup.errors.details[:status], {error: :invalid_for_slot}
    end

    test "rejects interested signups bound to a slot" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "interested")
      refute signup.valid?
    end

    test "allows tentative signups when there is no slot" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "tentative")
      assert signup.valid?
    end
  end

  class UniqueActiveSignupPerMemberTest < FleetEventSignupTest
    test "rejects a second active signup for the same member on the same event" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")
      other_slot = create(:fleet_event_slot, slottable: @team)
      duplicate = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: other_slot, fleet_membership: @fleet_membership, status: "confirmed")
      refute duplicate.valid?
    end

    test "allows another signup once the first is withdrawn" do
      first = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")
      first.withdraw!
      other_slot = create(:fleet_event_slot, slottable: @team)
      duplicate = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: other_slot, fleet_membership: @fleet_membership, status: "confirmed")
      assert duplicate.valid?
    end
  end

  class SlotNotAlreadyTakenTest < FleetEventSignupTest
    test "rejects a second signup on a slot that already has someone" do
      first_member = create(:fleet_membership, fleet: @event.fleet)
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: first_member, status: "confirmed")

      other = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")
      refute other.valid?
    end
  end

  class EffectiveSignupApprovalTest < FleetEventSignupTest
    test "uses the slot override when present" do
      @slot.update!(signup_approval: "confirmation_required")
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership)
      assert_equal "confirmation_required", signup.effective_signup_approval
    end

    test "falls back to the event default when the slot has none" do
      @event.update!(signup_approval: "confirmation_required")
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership)
      assert_equal "confirmation_required", signup.effective_signup_approval
    end
  end
end
