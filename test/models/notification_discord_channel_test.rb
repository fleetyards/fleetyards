# frozen_string_literal: true

require "test_helper"

# The Discord DM as a delivery channel of the existing notification system,
# rather than a separate path for one alert.
class NotificationDiscordChannelTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
    ::Discord::DeliverNotificationJob.jobs.clear
  end

  def notify!
    Notification.notify!(
      user: @user,
      type: :model_on_sale,
      title: "The Carrack is now on Sale!"
    )
  end

  # A user is created with a preference row per type already, so this updates
  # rather than creates.
  def prefer_discord!(enabled)
    preference = @user.notification_preferences
      .find_or_initialize_by(notification_type: :model_on_sale)
    preference.update!(discord: enabled)
  end

  test "delivers to Discord when the reader turned the channel on" do
    prefer_discord!(true)

    notification = notify!

    assert_equal 1, ::Discord::DeliverNotificationJob.jobs.size
    assert_equal notification.id, ::Discord::DeliverNotificationJob.jobs.first["args"].first
  end

  # An unsolicited DM from a bot is the fastest way to get an app reported.
  test "does not deliver to Discord by default" do
    notify!

    assert_equal 0, ::Discord::DeliverNotificationJob.jobs.size
  end

  test "does not deliver to Discord when the reader turned the channel off" do
    prefer_discord!(false)

    notify!

    assert_equal 0, ::Discord::DeliverNotificationJob.jobs.size
  end

  test "the channel is offered for a type that supports it" do
    assert_includes Notification.channels_for(:model_on_sale), :discord
  end

  test "the channel is not offered for a type that does not" do
    assert_not_includes Notification.channels_for(:fleet_invite), :discord
  end

  # Availability is per reader, not only per type: a DM needs somewhere to go.
  test "available only for a reader who linked a Discord account" do
    assert NotificationPreference.discord_available?(:model_on_sale, user: @user)

    @user.omniauth_connections.destroy_all

    refute NotificationPreference.discord_available?(:model_on_sale, user: @user.reload)
  end

  test "not available for a type without the channel, even with an account linked" do
    refute NotificationPreference.discord_available?(:fleet_invite, user: @user)
  end

  test "every type's defaults name the discord channel" do
    Notification.notification_types.each_key do |type|
      assert_includes NotificationPreference.defaults_for(type).keys, :discord, "missing for #{type}"
    end
  end

  test "a preference built from defaults has the channel off" do
    refute NotificationPreference.for(user: @user, type: :model_on_sale).discord?
  end
end
