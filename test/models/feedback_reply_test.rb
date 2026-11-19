# frozen_string_literal: true

require "test_helper"

class FeedbackReplyTest < ActiveSupport::TestCase
  test "an admin reply notifies the user with a link to the conversation" do
    feedback = create(:feedback)

    create(:feedback_reply, feedback:, from_admin: true, body: "Which ship?")

    notification = Notification.where(user: feedback.user, notification_type: "feedback_reply").sole
    assert_equal "Which ship?", notification.body
    assert_equal "/settings/feedback/#{feedback.id}/", notification.link
  end

  test "a user reply notifies admins rather than the user" do
    admin = create(:admin_user, resource_access: [:feedback])
    feedback = create(:feedback)
    AdminNotification.delete_all

    create(:feedback_reply, feedback:, body: "The Carrack")

    assert_empty Notification.where(notification_type: "feedback_reply")
    row = AdminNotification.where(admin_user: admin, notification_type: "feedback").sole
    assert_includes row.body, "The Carrack"
  end

  test "a user reply reopens resolved feedback" do
    feedback = create(:feedback, :resolved)

    create(:feedback_reply, feedback:, body: "Still slow")

    assert feedback.reload.open?
  end

  test "an admin reply leaves resolved feedback resolved" do
    feedback = create(:feedback, :resolved)

    create(:feedback_reply, feedback:, from_admin: true, body: "Fixed now")

    assert feedback.reload.resolved?
  end
end
