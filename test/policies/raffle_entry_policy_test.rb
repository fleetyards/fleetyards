# frozen_string_literal: true

require "test_helper"

class RaffleEntryPolicyTest < ActiveSupport::TestCase
  test "only a confirmed account may enter" do
    raffle = create(:raffle)
    confirmed = create(:user)
    unconfirmed = create(:user, confirmed_at: nil)

    assert policy(confirmed, raffle.entries.new(user: confirmed)).apply(:create?)
    assert_not policy(unconfirmed, raffle.entries.new(user: unconfirmed)).apply(:create?)
    assert_not policy(nil, raffle.entries.new).apply(:create?)
  end

  test "only the entrant may withdraw, and only while the raffle is open" do
    entry = create(:raffle_entry)

    assert policy(entry.user, entry).apply(:destroy?)
    assert_not policy(create(:user), entry).apply(:destroy?)

    entry.raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
    assert_not policy(entry.user, entry.reload).apply(:destroy?)
  end

  private def policy(user, entry)
    RaffleEntryPolicy.new(entry, user:)
  end
end
