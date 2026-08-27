# frozen_string_literal: true

require "test_helper"

module Cleanup
  class NotificationsJobTest < ActiveJob::TestCase
    setup do
      @user = create(:user)
      UserNotificationsChannel.stubs(:broadcast_to)
    end

    test "#perform archives what expired instead of deleting it" do
      notification = create(:notification, :expired, user: @user)

      ::Cleanup::NotificationsJob.new.perform

      assert notification.reload.archived?
    end

    test "#perform deletes what has served its term in the archive" do
      served = create(
        :notification,
        user: @user,
        archived_at: (Notification::ARCHIVE_RETENTION + 1.day).ago
      )
      kept = create(:notification, :archived, user: @user)

      ::Cleanup::NotificationsJob.new.perform

      assert_nil Notification.find_by(id: served.id)
      assert Notification.exists?(id: kept.id)
    end

    test "#perform still deletes expired admin notifications" do
      admin_notification = create(:admin_notification, :expired)

      ::Cleanup::NotificationsJob.new.perform

      assert_nil AdminNotification.find_by(id: admin_notification.id)
    end
  end
end
