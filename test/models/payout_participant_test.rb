# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: payout_participants
#
#  id               :uuid             not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  added_by_id      :uuid
#  payout_ledger_id :uuid             not null
#  user_id          :uuid
#
# Indexes
#
#  index_payout_participants_on_payout_ledger_id     (payout_ledger_id)
#  index_payout_participants_unique_user_per_ledger  (payout_ledger_id,user_id) UNIQUE WHERE (user_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (added_by_id => users.id)
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (user_id => users.id)
#
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

  test "keeps a departed user's handle so the ledger still reads" do
    user = create(:user)
    username = user.username
    participant = create(:payout_participant, payout_ledger: @ledger, user: user)

    user.destroy

    participant.reload

    assert_nil participant.user_id
    assert_equal username, participant.display_name
  end

  test "a user who organised a tour can still delete their account" do
    user = create(:user)
    tour = create(:tour, created_by: user)
    ledger = create(:payout_ledger, subject: tour)
    create(:payout_participant, payout_ledger: ledger, user: user)

    assert user.destroy
    assert_not Tour.exists?(tour.id)
  end

  test "a user who only joined someone else's tour can delete their account" do
    organiser = create(:user)
    joiner = create(:user)
    tour = create(:tour, created_by: organiser)
    ledger = create(:payout_ledger, subject: tour)
    participant = create(:payout_participant, payout_ledger: ledger, user: joiner)
    create(:payout_entry, payout_ledger: ledger, payout_participant: participant,
      recorded_by: joiner, amount: 25)

    assert joiner.destroy
    assert Tour.exists?(tour.id), "the organiser's tour must survive"
    assert PayoutEntry.exists?(payout_participant_id: participant.id)
  end

  # Both change the head count the profit is divided by, and the frozen payout
  # list was computed from the one that existed at settle time.
  test "cannot be added once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)

    participant = PayoutParticipant.new(payout_ledger: @ledger, user: create(:user))

    assert_not participant.valid?
  end

  test "cannot be removed once the ledger is settled" do
    participant = create(:payout_participant, payout_ledger: @ledger)
    @ledger.update!(status: "settled", settled_at: Time.current)

    assert_not participant.destroy
    assert PayoutParticipant.exists?(participant.id)
  end
end
