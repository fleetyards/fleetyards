# frozen_string_literal: true

require "test_helper"

class RsiRequestLogTest < ActiveSupport::TestCase
  setup do
    AdminNotificationsChannel.stubs(:broadcast_to)
    @admin_user = create(:admin_user, resource_access: [:"rsi-api-status"])
  end

  test "notifies admins with RSI status access when a request is blocked" do
    RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")

    notification = AdminNotification.find_by(admin_user: @admin_user, notification_type: "rsi_api_blocked")
    assert_not_nil notification
    assert_equal "error", notification.severity
    assert_equal "https://robertsspaceindustries.com/test", notification.body
  end

  test "folds repeat blocks of the same url into one notification" do
    2.times { RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test") }

    assert_equal 1, AdminNotification.where(notification_type: "rsi_api_blocked").count
    assert_equal 2, AdminNotification.find_by(notification_type: "rsi_api_blocked").occurrences
  end

  test "notifies again when the request is unblocked" do
    log = RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")

    log.update!(resolved: true)

    assert_not_nil AdminNotification.find_by(admin_user: @admin_user, notification_type: "rsi_api_unblocked")
  end
end
