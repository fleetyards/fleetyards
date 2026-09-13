# frozen_string_literal: true

require "test_helper"

class PayoutLedgerTest < ActiveSupport::TestCase
  test "refuses a subject type it does not know" do
    ledger = PayoutLedger.new(subject_type: "User", subject_id: create(:user).id)

    assert_not ledger.valid?
    assert_includes ledger.errors.attribute_names, :subject_type
  end

  test "allows at most one ledger per subject" do
    tour = create(:tour)
    create(:payout_ledger, subject: tour)

    duplicate = PayoutLedger.new(subject: tour)

    assert_not duplicate.valid?
  end

  test "seeds participants from a fleet event's active signups" do
    admin = create(:user)
    member = create(:user)
    fleet = create(:fleet, admins: [admin], members: [member])
    event = create(:fleet_event, fleet: fleet, created_by: admin)
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: event))
    membership = fleet.fleet_memberships.find_by(user_id: member.id)
    create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: membership)

    ledger = create(:payout_ledger, subject: event)
    ledger.seed_participants_from_subject!

    assert_equal [member.id], ledger.payout_participants.pluck(:user_id)
  end

  # Someone taken off the list on purpose must not reappear the next time the
  # ledger is opened or re-seeded.
  test "seeding never re-adds a removed participant more than once" do
    tour = create(:tour)
    ledger = create(:payout_ledger, subject: tour)

    ledger.seed_participants_from_subject!
    ledger.seed_participants_from_subject!

    assert_equal 1, ledger.payout_participants.count
  end

  test "settle freezes the computed transfers and marks the ledger settled" do
    ledger = create(:payout_ledger)
    alice = create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger, payout_participant: bob, amount: 100)

    ledger.settle!

    assert_predicate ledger, :settled?
    assert_equal 1, ledger.payout_transfers.count

    transfer = ledger.payout_transfers.first
    assert_equal bob.id, transfer.from_participant_id
    assert_equal alice.id, transfer.to_participant_id
    assert_equal 50, transfer.amount.to_i
  end

  test "reopen clears the frozen transfers" do
    ledger = create(:payout_ledger)
    create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger, payout_participant: bob, amount: 100)

    ledger.settle!
    ledger.reopen!

    assert_predicate ledger, :open?
    assert_empty ledger.payout_transfers
    assert_nil ledger.settled_at
  end

  test "settling twice does not stack transfers" do
    ledger = create(:payout_ledger)
    create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger, payout_participant: bob, amount: 100)

    ledger.settle!
    ledger.settle!

    assert_equal 1, ledger.payout_transfers.count
  end

  test "knows the fleet behind a fleet event, and none behind a tour" do
    fleet = create(:fleet)
    event = create(:fleet_event, fleet: fleet, created_by: create(:user))

    assert_equal fleet, create(:payout_ledger, subject: event).fleet
    assert_nil create(:payout_ledger, subject: create(:tour)).fleet
  end

  # Rails runs dependent callbacks in declaration order, and both entries and
  # transfers FK a participant row. Destroying participants first raised
  # InvalidForeignKey and left the ledger -- and its tour -- undeletable.
  test "is destroyed along with everything hanging off it" do
    ledger = create(:payout_ledger)
    alice = create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger, payout_participant: bob, amount: 100)
    ledger.settle!

    assert_difference "PayoutParticipant.count", -2 do
      assert_difference ["PayoutEntry.count", "PayoutTransfer.count"], -1 do
        assert ledger.destroy
      end
    end

    assert_not PayoutParticipant.exists?(alice.id)
  end

  test "a tour with a settled ledger can still be deleted" do
    tour = create(:tour)
    ledger = create(:payout_ledger, subject: tour)
    create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, payout_ledger: ledger, payout_participant: bob, amount: 40)
    ledger.settle!

    assert tour.destroy
    assert_not PayoutLedger.exists?(ledger.id)
  end

  test "seeds only the members who confirmed" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    event = create(:fleet_event, fleet: fleet, created_by: admin)
    team = create(:fleet_event_team, fleet_event: event)

    statuses = {"confirmed" => nil, "tentative" => nil, "interested" => nil}
    statuses.each_key do |status|
      member = create(:user)
      create(:fleet_membership, fleet: fleet, user: member,
        fleet_role: fleet.fleet_roles.ranked.last, aasm_state: :accepted)
      membership = fleet.fleet_memberships.find_by(user_id: member.id)

      slot = (status == "confirmed") ? create(:fleet_event_slot, slottable: team) : nil
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot,
        fleet_membership: membership, status: status)

      statuses[status] = member
    end

    ledger = create(:payout_ledger, subject: event)
    ledger.seed_participants_from_subject!

    assert_equal [statuses["confirmed"].id], ledger.payout_participants.pluck(:user_id)
  end

  # The controller's guard runs outside settle!'s transaction, so the model has
  # to re-check once it holds the lock. Without that, the second of two
  # simultaneous requests deletes and recreates the first one's transfers and
  # every confirmation ticked off against them goes with it.
  test "settling an already settled ledger answers false and changes nothing" do
    ledger = create(:payout_ledger)
    create(:payout_participant, payout_ledger: ledger)
    bob = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger, payout_participant: bob, amount: 100)

    assert ledger.settle!
    transfer = ledger.payout_transfers.first
    transfer.confirm!

    assert_not PayoutLedger.find(ledger.id).settle!

    assert_equal 1, ledger.reload.payout_transfers.count
    assert_predicate transfer.reload, :confirmed?
  end

  test "reopening an open ledger answers false" do
    ledger = create(:payout_ledger)

    assert_not ledger.reopen!
  end
end
