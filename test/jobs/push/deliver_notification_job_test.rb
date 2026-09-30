# frozen_string_literal: true

require "test_helper"

module Push
  class DeliverNotificationJobTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @notification = Notification.create!(user: @user, notification_type: :fleet_invite, title: "Invited")
      @subscriptions = create_list(:push_subscription, 2, user: @user)
      create(:push_subscription)
      Vapid.stubs(:configured?).returns(true)
      Flipper.enable(:push_notifications)
      @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(push: true)
      DeliverToSubscriptionJob.jobs.clear
    end

    def perform
      DeliverNotificationJob.new.perform(@notification.id)
    end

    test "enqueues one delivery per browser of the reader" do
      perform

      assert_equal @subscriptions.map { |s| [@notification.id, s.id] }.sort,
        DeliverToSubscriptionJob.jobs.map { |job| job["args"] }.sort
    end

    test "sends nothing without VAPID keys" do
      Vapid.stubs(:configured?).returns(false)

      perform

      assert_empty DeliverToSubscriptionJob.jobs
    end

    test "sends nothing with the flag off for the reader" do
      Flipper.disable(:push_notifications)

      perform

      assert_empty DeliverToSubscriptionJob.jobs
    end

    test "sends nothing when the reader has push off for the type" do
      @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(push: false)

      perform

      assert_empty DeliverToSubscriptionJob.jobs
    end

    test "sends nothing for a type without the push channel" do
      @notification.update!(notification_type: :hangar_create)

      perform

      assert_empty DeliverToSubscriptionJob.jobs
    end

    test "sends nothing for a notification that is gone" do
      @notification.destroy!

      perform

      assert_empty DeliverToSubscriptionJob.jobs
    end
  end
end
