# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261102180100_backfill_raffle_entry_email_keys.rb")

class BackfillRaffleEntryEmailKeysTest < ActiveSupport::TestCase
  test "keys the earliest entry of each inbox and leaves the later ones" do
    raffle = create(:raffle)
    first = create(:raffle_entry, raffle:, user: create(:user, email: "pilot+1@example.com"), created_at: 2.hours.ago)
    RaffleEntry.update_all(email_key: nil)
    second = create(:raffle_entry, raffle:, user: create(:user, email: "pilot+2@example.com"), created_at: 1.hour.ago)
    other = create(:raffle_entry, raffle:)
    RaffleEntry.update_all(email_key: nil)

    BackfillRaffleEntryEmailKeys.new.up

    assert_equal RaffleEntry.email_key_for("pilot@example.com"), first.reload.email_key
    assert_nil second.reload.email_key
    assert other.reload.email_key.present?
  end
end
