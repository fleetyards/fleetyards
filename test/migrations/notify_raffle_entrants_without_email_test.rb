# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261102180000_notify_raffle_entrants_without_email.rb")

class NotifyRaffleEntrantsWithoutEmailTest < ActiveSupport::TestCase
  test "tells placeholder entrants of every running raffle" do
    running = create(:raffle)
    upcoming = create(:raffle, :upcoming)
    first = create(:user, email: "1@users.noreply.fleetyards.net")
    second = create(:user, email: "2@users.noreply.fleetyards.net")
    create(:raffle_entry, raffle: running, user: first)
    create(:raffle_entry, :after_close, raffle: upcoming, user: second)

    NotifyRaffleEntrantsWithoutEmail.new.up

    assert_equal [first.id], Notification.where(notification_type: "raffle_email_missing").pluck(:user_id)
  end
end
