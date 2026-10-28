# frozen_string_literal: true

require "test_helper"

class RaffleEntryTest < ActiveSupport::TestCase
  test "entering snapshots the email and the accepted conditions" do
    user = create(:user, email: "pilot@example.com")

    entry = create(:raffle_entry, user:)

    assert_equal "pilot@example.com", entry.email
    assert_equal Raffle::CONDITIONS_VERSION, entry.conditions_version
    assert entry.conditions_accepted_at.present?
  end

  test "mail goes to the account's current address, or the snapshot once it is gone" do
    user = create(:user, email: "old@example.com")
    entry = create(:raffle_entry, user:)
    user.update_columns(email: "new@example.com")

    assert_equal "new@example.com", entry.reload.recipient_email

    entry.update_columns(user_id: nil)
    assert_equal "old@example.com", entry.reload.recipient_email
  end

  test "entering needs the conditions accepted" do
    entry = build(:raffle_entry, conditions_accepted: false)

    assert_not entry.valid?
    assert entry.errors.added?(:conditions_accepted, :accepted)
  end

  test "entering needs an open raffle" do
    assert_not build(:raffle_entry, raffle: create(:raffle, :closed)).valid?
    assert_not build(:raffle_entry, raffle: create(:raffle, :upcoming)).valid?
    assert_not build(:raffle_entry, raffle: create(:raffle, :draft)).valid?
  end

  test "a user enters a raffle once" do
    entry = create(:raffle_entry)

    assert_not build(:raffle_entry, raffle: entry.raffle, user: entry.user).valid?
  end

  test "masked_email keeps only the first characters" do
    assert_equal "p***@e***.com", build(:raffle_entry, user: nil, email: "pilot@example.com").masked_email
  end

  test "deleting an account removes entries of raffles not drawn yet" do
    entry = create(:raffle_entry)

    entry.user.destroy!

    assert_not RaffleEntry.exists?(entry.id)
  end

  test "deleting an account keeps entries of drawn raffles under the old name" do
    entry = create(:raffle_entry)
    username = entry.user.username
    entry.raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago, drawn_at: Time.current)

    entry.user.destroy!

    entry.reload
    assert_nil entry.user_id
    assert_equal username, entry.display_username
  end

  test "the claim token finds the entry while it answers for the same win" do
    entry = winning_entry
    token = entry.generate_token_for(:raffle_claim)

    assert_equal entry, RaffleEntry.find_by_token_for(:raffle_claim, token)

    entry.update!(won_at: 1.minute.ago)
    assert_nil RaffleEntry.find_by_token_for(:raffle_claim, token)
  end

  test "outcome follows the entry through the raffle" do
    entry = create(:raffle_entry)
    assert_equal "open", entry.outcome

    entry.raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
    assert_equal "waiting", entry.reload.outcome

    entry.raffle.update_columns(drawn_at: Time.current)
    assert_equal "not_won", entry.reload.outcome

    entry.update_columns(won_at: Time.current, claim_deadline_at: 1.day.from_now)
    assert_equal "won", entry.reload.outcome

    entry.update_columns(forfeited_at: Time.current)
    assert_equal "forfeited", entry.reload.outcome

    entry.update_columns(forfeited_at: nil, claimed_at: Time.current)
    assert_equal "claimed", entry.reload.outcome
  end

  test "claim! marks the win claimed once" do
    entry = winning_entry

    assert entry.claim!
    assert entry.claimed_at.present?
    assert_not entry.claim!
  end

  test "claim! refuses after the deadline" do
    entry = winning_entry(claim_deadline_at: 1.minute.ago)

    assert_not entry.claim!
    assert_nil entry.reload.claimed_at
  end

  private def winning_entry(claim_deadline_at: 2.days.from_now)
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
    create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at:)
  end
end
