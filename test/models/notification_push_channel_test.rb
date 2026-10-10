# frozen_string_literal: true

require "test_helper"

class NotificationPushChannelTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    ::Push::DeliverNotificationJob.jobs.clear
    Push::Vapid.stubs(:configured?).returns(true)
    Flipper.enable(:push_notifications)
  end

  def notify!(type: :fleet_invite)
    Notification.notify!(user: @user, type:, title: "Invited")
  end

  def prefer_push!(enabled, type: :fleet_invite)
    @user.notification_preferences.find_or_initialize_by(notification_type: type).update!(push: enabled)
  end

  test "enqueues a push when the reader turned the channel on" do
    prefer_push!(true)

    notification = notify!

    assert_equal [[notification.id, false]], ::Push::DeliverNotificationJob.jobs.map { |job| job["args"] }
  end

  test "marks the push seen when a tab of the reader's was in use for the toast" do
    prefer_push!(true)
    UserPresence.mark_active(@user.id, "tab-1")

    notification = notify!

    assert_equal [[notification.id, true]], ::Push::DeliverNotificationJob.jobs.map { |job| job["args"] }
  ensure
    UserPresence.mark_inactive(@user.id, "tab-1")
  end

  test "does not mark the push seen when the reader has the in-app channel off" do
    prefer_push!(true)
    @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(app: false)
    UserPresence.mark_active(@user.id, "tab-1")

    notification = notify!

    assert_equal [[notification.id, false]], ::Push::DeliverNotificationJob.jobs.map { |job| job["args"] }
  ensure
    UserPresence.mark_inactive(@user.id, "tab-1")
  end

  test "does not mark the push seen when the toast failed" do
    prefer_push!(true)
    UserPresence.mark_active(@user.id, "tab-1")
    UserNotificationsChannel.stubs(:broadcast_to).raises("cable is down")

    notification = notify!

    assert_equal [[notification.id, false]], ::Push::DeliverNotificationJob.jobs.map { |job| job["args"] }
  ensure
    UserPresence.mark_inactive(@user.id, "tab-1")
  end

  test "a mailer that raises does not cost the reader the push" do
    prefer_push!(true)
    @user.notification_preferences.find_by!(notification_type: :fleet_invite).update!(mail: true)
    Notification.stubs(:mailer_for).returns(->(_notification) { raise "mail is down" })

    notify!

    assert_equal 1, ::Push::DeliverNotificationJob.jobs.size
  end

  test "does not push by default" do
    notify!

    assert_empty ::Push::DeliverNotificationJob.jobs
  end

  test "does not push when the reader turned the channel off" do
    prefer_push!(false)

    notify!

    assert_empty ::Push::DeliverNotificationJob.jobs
  end

  test "every type's defaults have push off" do
    Notification.notification_types.each_key do |type|
      refute NotificationPreference.defaults_for(type)[:push], "push on by default for #{type}"
    end
  end

  test "the channel is offered for a type that supports it" do
    assert NotificationPreference.push_available?(:fleet_invite, user: @user)
  end

  test "the channel is not offered for a type without it" do
    refute NotificationPreference.push_available?(:inventory_transfer_resolved, user: @user)
  end

  test "the channel is not offered with the flag off for the reader" do
    Flipper.disable(:push_notifications)

    refute NotificationPreference.push_available?(:fleet_invite, user: @user)
  end

  test "the channel is not offered without VAPID keys" do
    Push::Vapid.stubs(:configured?).returns(false)

    refute NotificationPreference.push_available?(:fleet_invite, user: @user)
  end
end
