# frozen_string_literal: true

require "test_helper"

module Push
  class DeliverToSubscriptionJobTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @notification = Notification.create!(user: @user, notification_type: :fleet_invite, title: "Invited", link: "/fleets/invites")
      @subscription = create(:push_subscription, user: @user, failure_count: 2, last_failed_at: 1.day.ago)
      Vapid.stubs(:configured?).returns(true)
      Vapid.stubs(:public_key).returns("public")
      Vapid.stubs(:private_key).returns("private")
      Vapid.stubs(:subject).returns("mailto:info@fleetyards.net")
      Flipper.enable(:push_notifications)
      @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(push: true)
    end

    def perform
      DeliverToSubscriptionJob.new.perform(@notification.id, @subscription.id)
    end

    def response_error(klass)
      klass.new(stub(body: "", inspect: "response"), "fcm.googleapis.com")
    end

    test "sends the payload to the browser with the stored keys" do
      WebPush.expects(:payload_send).with do |args|
        JSON.parse(args[:message])["notificationId"] == @notification.id &&
          args[:endpoint] == @subscription.endpoint &&
          args[:p256dh] == @subscription.p256dh_key &&
          args[:auth] == @subscription.auth_key &&
          args[:vapid] == {subject: "mailto:info@fleetyards.net", public_key: "public", private_key: "private"}
      end

      perform
    end

    test "a delivery clears the failure count" do
      WebPush.stubs(:payload_send)

      perform

      @subscription.reload
      assert @subscription.last_delivered_at.present?
      assert_equal 0, @subscription.failure_count
      assert_nil @subscription.last_failed_at
    end

    [WebPush::ExpiredSubscription, WebPush::InvalidSubscription].each do |klass|
      test "#{klass.name.demodulize} removes the subscription" do
        WebPush.stubs(:payload_send).raises(response_error(klass))

        perform

        refute PushSubscription.exists?(@subscription.id)
      end
    end

    [WebPush::TooManyRequests, WebPush::PushServiceError].each do |klass|
      test "#{klass.name.demodulize} is left for Sidekiq to retry" do
        WebPush.stubs(:payload_send).raises(response_error(klass))

        assert_raises(klass) { perform }
        assert_equal 2, @subscription.reload.failure_count
      end
    end

    test "a timeout is left for Sidekiq to retry" do
      WebPush.stubs(:payload_send).raises(Net::ReadTimeout)

      assert_raises(Net::ReadTimeout) { perform }
    end

    test "any other refusal counts against the subscription" do
      WebPush.stubs(:payload_send).raises(response_error(WebPush::Unauthorized))

      perform

      @subscription.reload
      assert_equal 3, @subscription.failure_count
      assert @subscription.last_failed_at > 1.minute.ago
    end

    test "a subscription that keeps failing goes" do
      @subscription.update_columns(failure_count: DeliverToSubscriptionJob::MAX_FAILURES - 1)
      WebPush.stubs(:payload_send).raises(response_error(WebPush::PayloadTooLarge))

      perform

      refute PushSubscription.exists?(@subscription.id)
    end

    test "a racing failure is counted from the database, not the loaded row" do
      stale = PushSubscription.find(@subscription.id)
      @subscription.update_columns(failure_count: 3)

      DeliverToSubscriptionJob.record_failure(stale)

      assert_equal 4, @subscription.reload.failure_count
    end

    test "sends nothing when the reader switched push off after fan-out" do
      @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(push: false)
      WebPush.expects(:payload_send).never

      perform
    end

    test "sends nothing when the flag went off after fan-out" do
      Flipper.disable(:push_notifications)
      WebPush.expects(:payload_send).never

      perform
    end

    test "exhausted retries for a browser that moved accounts do not count against its new owner" do
      @subscription.update_columns(user_id: create(:user).id)

      DeliverToSubscriptionJob.sidekiq_retries_exhausted_block.call(
        {"args" => [@notification.id, @subscription.id]}, WebPush::TooManyRequests.allocate
      )

      assert_equal 2, @subscription.reload.failure_count
    end

    test "exhausted retries count as a failure" do
      DeliverToSubscriptionJob.sidekiq_retries_exhausted_block.call(
        {"args" => [@notification.id, @subscription.id]}, WebPush::TooManyRequests.allocate
      )

      assert_equal 3, @subscription.reload.failure_count
    end

    # The browser may have moved to another account between queueing and
    # sending; the notification is not that account's to receive.
    test "sends nothing to a browser that now belongs to someone else" do
      @subscription.update_columns(user_id: create(:user).id)
      WebPush.expects(:payload_send).never

      perform
    end

    test "sends nothing without VAPID keys" do
      Vapid.stubs(:configured?).returns(false)
      WebPush.expects(:payload_send).never

      perform
    end

    test "does nothing for a subscription that is gone" do
      @subscription.destroy!
      WebPush.expects(:payload_send).never

      perform
    end
  end
end
