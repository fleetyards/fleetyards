# frozen_string_literal: true

require "test_helper"

class FeedbackTest < ActiveSupport::TestCase
  test "new feedback notifies admins who can read it, in one row for the queue" do
    reader = create(:admin_user, resource_access: [:feedback])
    other = create(:admin_user, resource_access: [:users])

    create(:feedback)
    create(:feedback)

    rows = AdminNotification.where(notification_type: "feedback")
    assert_equal [reader.id], rows.pluck(:admin_user_id)
    assert_equal "2 open feedback messages", rows.first.title
    assert_empty AdminNotification.where(admin_user: other)
  end

  test "rejects a feature name the registry does not know" do
    feedback = build(:feedback, feature_name: "no-such-flag")

    assert_not feedback.valid?
    assert feedback.errors.added?(:feature_name, :inclusion, value: "no-such-flag")
  end

  test "rejects a message over the limit" do
    assert_not build(:feedback, message: "a" * (Feedback::MESSAGE_MAX_LENGTH + 1)).valid?
  end

  test "reopening clears the resolution" do
    admin = create(:admin_user, resource_access: [:feedback])
    feedback = create(:feedback)
    feedback.resolved_by = admin
    feedback.resolve!

    assert feedback.resolved_at

    feedback.reopen!

    assert feedback.reload.open?
    assert_nil feedback.resolved_by_id
    assert_nil feedback.resolved_at
  end
end
