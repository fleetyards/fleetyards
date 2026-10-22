# frozen_string_literal: true

require "test_helper"

class FleetEventSignupTest < ActiveSupport::TestCase
  setup do
    @event = create(:fleet_event, :open)
    @team = create(:fleet_event_team, fleet_event: @event)
    @slot = create(:fleet_event_slot, slottable: @team)
    @fleet_membership = create(:fleet_membership, fleet: @event.fleet)
  end

  class ReferencesExistTest < FleetEventSignupTest
    test "rejects a slot that no longer exists" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot_id: SecureRandom.uuid, fleet_membership: @fleet_membership, status: "confirmed")
      refute signup.valid?
      assert_includes signup.errors.details[:fleet_event_slot_id], {error: :required}
    end

    test "rejects a slot that no longer exists when the event is unknown too" do
      signup = build(:fleet_event_signup, fleet_event: nil, fleet_event_slot_id: SecureRandom.uuid, fleet_membership: @fleet_membership, status: "confirmed")
      refute signup.valid?
      assert_includes signup.errors.details[:fleet_event_slot_id], {error: :required}
    end

    test "rejects a vehicle that no longer exists" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, vehicle_id: SecureRandom.uuid)
      refute signup.valid?
      assert_includes signup.errors.details[:vehicle_id], {error: :required}
    end
  end

  # Validation is a read, so a request whose checks ran before a concurrent
  # claim or delete landed reaches the write regardless -- which is what
  # stubbing `valid?` reproduces.
  class SaveWithoutConflictTest < FleetEventSignupTest
    test "answers a lost slot claim with the taken error" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: create(:fleet_membership, fleet: @event.fleet), status: "confirmed")
      loser = racing(build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed"))

      assert_not loser.save_without_conflict
      assert_equal [:already_taken], loser.errors.where(:fleet_event_slot_id).map(&:type)
      assert_equal 1, @slot.active_signups.count
    end

    test "answers a second active signup for the member on an occurrence with the signed-up error" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested", occurrence_date: Date.current)
      loser = racing(build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested", occurrence_date: Date.current))

      assert_not loser.save_without_conflict
      assert_equal [:already_signed_up], loser.errors.where(:fleet_membership_id).map(&:type)
    end

    test "answers a second active signup for the member on a one-off event with the signed-up error" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested")
      loser = racing(build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested"))

      assert_not loser.save_without_conflict
      assert_equal [:already_signed_up], loser.errors.where(:fleet_membership_id).map(&:type)
    end

    test "answers a slot deleted mid-save with the required error" do
      signup = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested")
      other_slot = create(:fleet_event_slot, slottable: @team)
      other_slot_id = other_slot.id
      other_slot.destroy!

      assert_not racing(signup).update_without_conflict(fleet_event_slot_id: other_slot_id, status: "confirmed")
      assert_equal [:required], signup.errors.where(:fleet_event_slot_id).map(&:type)
      assert_nil signup.reload.fleet_event_slot_id
    end

    test "answers a vehicle deleted mid-save with the required error" do
      vehicle = create(:vehicle, user: @fleet_membership.user)
      signup = racing(build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, vehicle_id: vehicle.id))
      Vehicle.where(id: vehicle.id).delete_all

      assert_not signup.save_without_conflict
      assert_equal [:required], signup.errors.where(:vehicle_id).map(&:type)
    end

    test "leaves a caller's transaction usable" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: create(:fleet_membership, fleet: @event.fleet), status: "confirmed")
      loser = racing(build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed"))

      FleetEventSignup.transaction do
        assert_not loser.save_without_conflict
        assert_equal 1, @slot.active_signups.count
      end
    end

    test "a slot destroy sweeps a signup that claimed it after the signups were loaded" do
      slot = FleetEventSlot.find(@slot.id)
      slot.fleet_event_signups.load
      straggler = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")

      slot.destroy!

      assert_not FleetEventSignup.exists?(straggler.id)
    end

    private def racing(signup)
      signup.define_singleton_method(:valid?) { |*| true }
      signup
    end
  end

  class VehicleOwnedByMemberTest < FleetEventSignupTest
    test "accepts a vehicle from the member's hangar" do
      vehicle = create(:vehicle, user: @fleet_membership.user)
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, vehicle: vehicle)
      assert signup.valid?
    end

    test "rejects another user's vehicle" do
      signup = build(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, vehicle: create(:vehicle))
      refute signup.valid?
      assert_includes signup.errors.details[:vehicle_id], {error: :not_owned}
    end

    test "keeps a signup editable after its vehicle changed hands" do
      vehicle = create(:vehicle, user: @fleet_membership.user)
      signup = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, vehicle: vehicle)
      vehicle.update_columns(user_id: create(:user).id)

      assert signup.update(notes: "bringing snacks")
    end
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

    test "rejects moving a signup onto a taken slot" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: create(:fleet_membership, fleet: @event.fleet), status: "confirmed")
      signup = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @fleet_membership, status: "interested")

      refute signup.update(fleet_event_slot: @slot, status: "confirmed")
      assert_includes signup.errors.details[:fleet_event_slot_id], {error: :already_taken}
    end

    test "rejects reviving a withdrawn signup on a slot taken since" do
      signup = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership, status: "confirmed")
      signup.withdraw!
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: create(:fleet_membership, fleet: @event.fleet), status: "confirmed")

      refute signup.update(status: "confirmed")
      assert_includes signup.errors.details[:fleet_event_slot_id], {error: :already_taken}
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
