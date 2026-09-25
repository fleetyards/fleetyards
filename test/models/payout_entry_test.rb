# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: payout_entries
#
#  id                    :uuid             not null, primary key
#  amount                :decimal(15, 2)   not null
#  decline_reason        :text
#  description           :string           not null
#  entry_type            :integer          default("expense"), not null
#  notes                 :text
#  occurred_at           :datetime
#  review_status         :integer          default("approved"), not null
#  reviewed_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payout_ledger_id      :uuid             not null
#  payout_participant_id :uuid             not null
#  recorded_by_id        :uuid
#  reviewed_by_id        :uuid
#
# Indexes
#
#  index_payout_entries_on_payout_ledger_id_and_entry_type     (payout_ledger_id,entry_type)
#  index_payout_entries_on_payout_ledger_id_and_review_status  (payout_ledger_id,review_status)
#  index_payout_entries_on_payout_participant_id               (payout_participant_id)
#
# Foreign Keys
#
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (payout_participant_id => payout_participants.id)
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (reviewed_by_id => users.id)
#
class PayoutEntryTest < ActiveSupport::TestCase
  setup do
    @ledger = create(:payout_ledger)
    @participant = create(:payout_participant, payout_ledger: @ledger)
  end

  test "requires a positive amount" do
    entry = PayoutEntry.new(payout_ledger: @ledger, payout_participant: @participant,
      amount: 0, description: "Nothing")

    assert_not entry.valid?
    assert_includes entry.errors.attribute_names, :amount
  end

  test "refuses a negative amount, since direction lives in the entry type" do
    entry = PayoutEntry.new(payout_ledger: @ledger, payout_participant: @participant,
      amount: -5, description: "Refund")

    assert_not entry.valid?
  end

  test "requires a description" do
    entry = PayoutEntry.new(payout_ledger: @ledger, payout_participant: @participant, amount: 10)

    assert_not entry.valid?
    assert_includes entry.errors.attribute_names, :description
  end

  test "refuses a participant from a different ledger" do
    entry = PayoutEntry.new(payout_ledger: @ledger, amount: 10, description: "Fuel",
      payout_participant: create(:payout_participant))

    assert_not entry.valid?
    assert_includes entry.errors.attribute_names, :payout_participant_id
  end

  test "refuses to be written once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)

    entry = PayoutEntry.new(payout_ledger: @ledger, payout_participant: @participant,
      amount: 10, description: "Late")

    assert_not entry.valid?
  end

  test "keeps two decimal places" do
    entry = create(:payout_entry, payout_ledger: @ledger, payout_participant: @participant, amount: "1200.55")

    assert_equal BigDecimal("1200.55"), entry.reload.amount
  end

  # The lock is what makes this deterministic: without it the entry's
  # open-ledger check and PayoutLedger#settle! can both pass on the same
  # ledger, and money lands in a payout list that was already frozen.
  test "an entry written against a ledger settled in the meantime is refused" do
    other = PayoutLedger.find(@ledger.id)
    other.settle!

    entry = PayoutEntry.new(payout_ledger: @ledger, payout_participant: @participant,
      amount: 10, description: "Late")

    assert_not entry.valid?
    assert_equal 0, @ledger.reload.payout_entries.count
  end

  # Validations do not run on destroy, so this needed a callback of its own --
  # money must not leave a ledger whose payout list was frozen around it.
  test "cannot be destroyed once the ledger is settled" do
    entry = create(:payout_entry, payout_ledger: @ledger, payout_participant: @participant)
    @ledger.update!(status: "settled", settled_at: Time.current)

    assert_not entry.destroy
    assert PayoutEntry.exists?(entry.id)
  end

  test "refuses an expense on a contract that does not reimburse them" do
    contract = create(:fleet_contract, :fulfilled, reimburse_expenses: false)
    ledger = contract.create_payout_ledger!
    participant = create(:payout_participant, payout_ledger: ledger)

    expense = build(:payout_entry, payout_ledger: ledger, payout_participant: participant)
    assert_not expense.valid?
    assert_includes expense.errors.details[:entry_type], {error: :not_reimbursed}

    assert_predicate build(:payout_entry, :income, payout_ledger: ledger, payout_participant: participant), :valid?
  end

  test "sends an approved expense back to review when its amount changes" do
    entry = create(:payout_entry)
    entry.approve!(create(:user))

    entry.amount = 5_000
    entry.assign_review_status(by_manager: false)

    assert_predicate entry, :review_pending?
    assert_nil entry.reviewed_by
  end

  test "a participant's pending expense tells the managers, not the one who recorded it" do
    organiser = create(:user)
    member = create(:user)
    ledger = create(:payout_ledger, subject: create(:tour, created_by: organiser))
    member_p = create(:payout_participant, payout_ledger: ledger, user: member)

    create(:payout_entry, :pending, payout_ledger: ledger, payout_participant: member_p,
      recorded_by: member, description: "Refuel")

    notification = Notification.payout_entry_pending_review.sole
    assert_equal organiser, notification.user
    assert_equal "Refuel", notification.body
    assert_equal "/tools/tours/#{ledger.subject.slug}/", notification.link
  end

  test "a contractor's pending expense reaches the contract's author and managers" do
    author = create(:user)
    officer = create(:user)
    contractor = create(:user)
    fleet = create(:fleet, admins: [officer], members: [author, contractor])
    contract = create(:fleet_contract, :fulfilled, fleet: fleet, created_by: author)
    ledger = contract.create_payout_ledger!
    contractor_p = create(:payout_participant, payout_ledger: ledger, user: contractor)

    create(:payout_entry, :pending, payout_ledger: ledger, payout_participant: contractor_p, recorded_by: contractor)

    assert_equal [author, officer].map(&:id).sort, Notification.payout_entry_pending_review.pluck(:user_id).sort
    assert_equal "/fleets/#{fleet.slug}/contracts/#{contract.slug}/payouts/",
      Notification.payout_entry_pending_review.first.link
  end

  test "declining tells whoever recorded the expense, with the reason" do
    organiser = create(:user)
    member = create(:user)
    ledger = create(:payout_ledger, subject: create(:tour, created_by: organiser))
    member_p = create(:payout_participant, payout_ledger: ledger, user: member)
    entry = create(:payout_entry, :pending, payout_ledger: ledger, payout_participant: member_p, recorded_by: member)

    entry.decline!(organiser, reason: "No receipt")

    notification = Notification.payout_entry_declined.sole
    assert_equal member, notification.user
    assert_equal "No receipt", notification.body
  end

  test "approving an expense tells nobody" do
    organiser = create(:user)
    ledger = create(:payout_ledger, subject: create(:tour, created_by: organiser))
    entry = create(:payout_entry, :pending, payout_ledger: ledger,
      payout_participant: create(:payout_participant, payout_ledger: ledger))

    assert_no_difference -> { Notification.count } do
      entry.approve!(organiser)
    end
  end
end
