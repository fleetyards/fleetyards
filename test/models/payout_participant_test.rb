# frozen_string_literal: true

require "test_helper"

class PayoutParticipantTest < ActiveSupport::TestCase
  setup do
    @ledger = create(:payout_ledger)
  end

  test "requires a name when there is no user" do
    participant = PayoutParticipant.new(payout_ledger: @ledger)

    assert_not participant.valid?
    assert_includes participant.errors.attribute_names, :name
  end

  test "accepts a guest with a name and no account" do
    participant = PayoutParticipant.new(payout_ledger: @ledger, name: "Kev")

    assert_predicate participant, :valid?
    assert_predicate participant, :guest?
    assert_equal "Kev", participant.display_name
  end

  test "prefers the username over a stored name" do
    user = create(:user)
    participant = create(:payout_participant, payout_ledger: @ledger, user: user, name: "ignored")

    assert_equal user.username, participant.display_name
  end

  test "refuses the same user twice on one ledger" do
    user = create(:user)
    create(:payout_participant, payout_ledger: @ledger, user: user)

    assert_not PayoutParticipant.new(payout_ledger: @ledger, user: user).valid?
  end

  test "allows the same user on two different ledgers" do
    user = create(:user)
    create(:payout_participant, payout_ledger: @ledger, user: user)

    assert_predicate PayoutParticipant.new(payout_ledger: create(:payout_ledger), user: user), :valid?
  end

  # Removing someone re-divides the profit, so a participant carrying entries
  # cannot just vanish and leave them orphaned.
  test "refuses to be destroyed while it has entries" do
    participant = create(:payout_participant, payout_ledger: @ledger)
    create(:payout_entry, payout_ledger: @ledger, payout_participant: participant)

    assert_not participant.destroy
    assert PayoutParticipant.exists?(participant.id)
  end

  test "can be destroyed once it has no entries" do
    participant = create(:payout_participant, payout_ledger: @ledger)

    assert participant.destroy
  end
end
