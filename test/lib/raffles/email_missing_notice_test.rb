# frozen_string_literal: true

require "test_helper"

module Raffles
  class EmailMissingNoticeTest < ActiveSupport::TestCase
    setup do
      @raffle = create(:raffle)
      @placeholder = create(:user, email: "12345@users.noreply.fleetyards.net")
      create(:raffle_entry, raffle: @raffle, user: @placeholder)
      create(:raffle_entry, raffle: @raffle)
    end

    test "notifies only the entrants with a placeholder address" do
      assert_difference -> { Notification.where(notification_type: "raffle_email_missing").count }, 1 do
        assert_equal 1, EmailMissingNotice.new(@raffle).call
      end

      notification = Notification.find_by(notification_type: "raffle_email_missing")
      assert_equal @placeholder, notification.user
      assert_equal @raffle, notification.record
      assert_includes notification.title, @raffle.localized_title
    end

    test "leaves a closed raffle alone" do
      @raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)

      assert_no_difference -> { Notification.count } do
        assert_equal 0, EmailMissingNotice.new(@raffle).call
      end
    end
  end
end
