# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: payout_entries
#
#  id                    :uuid             not null, primary key
#  amount                :decimal(15, 2)   not null
#  description           :string           not null
#  entry_type            :integer          default(0), not null
#  notes                 :text
#  occurred_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payout_ledger_id      :uuid             not null
#  payout_participant_id :uuid             not null
#  recorded_by_id        :uuid
#
# Indexes
#
#  index_payout_entries_on_payout_ledger_id                 (payout_ledger_id)
#  index_payout_entries_on_payout_ledger_id_and_entry_type  (payout_ledger_id,entry_type)
#  index_payout_entries_on_payout_participant_id            (payout_participant_id)
#
# Foreign Keys
#
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (payout_participant_id => payout_participants.id)
#  fk_rails_...  (recorded_by_id => users.id)
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
end
