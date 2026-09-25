# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: payout_ledgers
#
#  id            :uuid             not null, primary key
#  notes         :text
#  settled_at    :datetime
#  status        :string           default("open"), not null
#  subject_type  :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  settled_by_id :uuid
#  subject_id    :uuid             not null
#
# Indexes
#
#  index_payout_ledgers_on_subject_type_and_subject_id  (subject_type,subject_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (settled_by_id => users.id)
#
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

  test "seeds a contract with the fleet as payer, contractors weighted by what they delivered" do
    lead = create(:user)
    crew = create(:user)
    contract = create(:fleet_contract, :fulfilled, reward: 1_000)
    Contracts::Progress.any_instance.stubs(:weights).returns({lead.id => BigDecimal("0.75"), crew.id => BigDecimal("0.25")})

    ledger = contract.create_payout_ledger!
    ledger.seed_participants_from_subject!

    payer = ledger.payout_participants.find_by!(fleet_id: contract.fleet_id)
    assert_equal 75, ledger.payout_participants.find_by!(user_id: lead.id).weight
    assert_equal 25, ledger.payout_participants.find_by!(user_id: crew.id).weight

    reward = ledger.payout_entries.sole
    assert_predicate reward, :income?
    assert_predicate reward, :review_approved?
    assert_equal payer, reward.payout_participant
    assert_equal 1_000, reward.amount
  end

  test "keeps a contractor whose share rounds below a hundredth on the list" do
    lead = create(:user)
    crew = create(:user)
    contract = create(:fleet_contract, :fulfilled)
    Contracts::Progress.any_instance.stubs(:weights).returns({lead.id => 1.to_d, crew.id => BigDecimal("0.00001")})

    ledger = contract.create_payout_ledger!
    ledger.seed_participants_from_subject!

    assert_equal BigDecimal("0.01"), ledger.payout_participants.find_by!(user_id: crew.id).weight
  end

  test "divides evenly across the contractors when nothing was measured" do
    contract = create(:fleet_contract, :fulfilled, reward: 0)
    create(:fleet_contract_assignment, :lead, fleet_contract: contract)
    create(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    ledger = contract.create_payout_ledger!
    ledger.seed_participants_from_subject!

    assert_equal [1, 1], ledger.payout_participants.where.not(user_id: nil).pluck(:weight)
    assert_empty ledger.payout_entries
  end

  test "settling a contract's ledger settles the contract, and reopening puts it back" do
    contract = create(:fleet_contract, :fulfilled)
    ledger = contract.create_payout_ledger!

    fulfilled_at = contract.fulfilled_at

    assert ledger.settle!
    assert_predicate contract.reload, :settled?
    assert_not_nil contract.settled_at

    assert ledger.reopen!
    assert_predicate contract.reload, :fulfilled?
    assert_nil contract.settled_at
    assert_in_delta fulfilled_at, contract.fulfilled_at, 1.second
  end

  test "settling tells every participant but the one who settled it" do
    organiser = create(:user)
    member = create(:user)
    tour = create(:tour, created_by: organiser)
    ledger = create(:payout_ledger, subject: tour)
    create(:payout_participant, payout_ledger: ledger, user: organiser)
    create(:payout_participant, payout_ledger: ledger, user: member)
    create(:payout_participant, :guest, payout_ledger: ledger)

    assert_difference -> { Notification.payout_ledger_settled.count }, 1 do
      ledger.settle!(organiser)
    end

    notification = Notification.payout_ledger_settled.sole
    assert_equal member, notification.user
    assert_equal "/tools/tours/#{tour.slug}/", notification.link
  end

  test "settling a contract tells its contractors and its author" do
    author = create(:user)
    contractor = create(:user)
    officer = create(:user)
    contract = create(:fleet_contract, :fulfilled, created_by: author)
    ledger = contract.create_payout_ledger!
    create(:payout_participant, :fleet, payout_ledger: ledger, fleet: contract.fleet)
    create(:payout_participant, payout_ledger: ledger, user: contractor)

    ledger.settle!(officer)

    assert_equal [author, contractor].map(&:id).sort, Notification.fleet_contract_settled.pluck(:user_id).sort
    assert_equal "/fleets/#{contract.fleet.slug}/contracts/#{contract.slug}", Notification.fleet_contract_settled.first.link
  end

  test "a refused settle tells nobody" do
    ledger = create(:payout_ledger)
    create(:payout_participant, payout_ledger: ledger)
    ledger.update!(status: "settled")

    assert_no_difference -> { Notification.count } do
      ledger.settle!
    end
  end
end
