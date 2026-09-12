# frozen_string_literal: true

require "test_helper"

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
end
