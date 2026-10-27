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

  test "the email snapshot outlives a changed account email" do
    user = create(:user, email: "old@example.com")
    entry = create(:raffle_entry, user:)

    user.update_columns(email: "new@example.com")

    assert_equal "old@example.com", entry.reload.email
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

    duplicate = build(:raffle_entry, raffle: entry.raffle, user: entry.user)

    assert_not duplicate.valid?
  end

  test "masked_email keeps only the first characters" do
    assert_equal "p***@e***.com", build(:raffle_entry, email: "pilot@example.com").masked_email
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

  test "claim! marks the win claimed and concludes the raffle" do
    entry = winning_entry

    assert entry.claim!
    assert entry.claimed_at.present?
    assert entry.raffle.reload.concluded?
  end

  test "claim! refuses after the deadline" do
    entry = winning_entry(claim_deadline_at: 1.minute.ago)

    assert_not entry.claim!
    assert_nil entry.reload.claimed_at
  end

  test "no verification code for a winner who still has an account" do
    assert_nil winning_entry.issue_verification_code!
  end

  test "a verification code claims the win for an admin" do
    entry = deleted_account_winner
    admin = create(:admin_user)

    code = entry.issue_verification_code!

    assert_match(/\A\d{6}\z/, code)
    assert_equal :claimed, entry.verify_and_claim!(code, admin_user: admin)
    assert_equal admin, entry.reload.claimed_by
    assert entry.raffle.reload.concluded?
  end

  test "a wrong verification code counts an attempt and locks out after five" do
    entry = deleted_account_winner
    code = entry.issue_verification_code!
    wrong = (code == "000000") ? "111111" : "000000"
    admin = create(:admin_user)

    RaffleEntry::VERIFICATION_MAX_ATTEMPTS.times do
      assert_equal :invalid, entry.verify_and_claim!(wrong, admin_user: admin)
    end

    assert_equal :too_many_attempts, entry.verify_and_claim!(code, admin_user: admin)
    assert_nil entry.reload.claimed_at
  end

  test "a verification code expires" do
    entry = deleted_account_winner
    code = entry.issue_verification_code!

    travel RaffleEntry::VERIFICATION_CODE_TTL + 1.minute do
      assert_equal :expired, entry.verify_and_claim!(code, admin_user: create(:admin_user))
    end
  end

  test "a new verification code waits for the resend interval" do
    entry = deleted_account_winner

    assert entry.issue_verification_code!
    assert_nil entry.issue_verification_code!

    travel RaffleEntry::VERIFICATION_RESEND_INTERVAL + 1.second do
      assert entry.issue_verification_code!
    end
  end

  private def deleted_account_winner
    winning_entry.tap { |entry| entry.update_columns(user_id: nil, username: "gone") }
  end

  private def winning_entry(claim_deadline_at: 5.days.from_now)
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
    create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at:)
  end
end
