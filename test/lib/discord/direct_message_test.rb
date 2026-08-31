# frozen_string_literal: true

require "test_helper"
require "discord/direct_message"

module Discord
  class DirectMessageTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
      @notification = Notification.create!(
        user: @user,
        notification_type: :model_on_sale,
        title: "The Carrack is now on Sale!",
        body: "Starting at $600.00",
        link: "/ships/carrack"
      )

      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      ::Discord::ApiClient.stubs(:new).returns(@api)
    end

    def deliver
      ::Discord::DirectMessage.new(@notification).run
    end

    test "opens a DM channel with the reader's Discord account" do
      @api.expects(:create_dm_channel).with("discord-uid-1").returns({"id" => "channel-1"})
      @api.expects(:create_message).with("channel-1", anything)

      assert deliver
    end

    test "sends the notification as an embed" do
      @api.stubs(:create_dm_channel).returns({"id" => "channel-1"})
      @api.expects(:create_message).with do |_channel, payload|
        embed = payload[:embeds].first
        embed[:title] == "The Carrack is now on Sale!" && embed[:description] == "Starting at $600.00"
      end

      deliver
    end

    # A notification link is a path, and a DM has no site around it.
    test "makes the notification's link absolute" do
      @api.stubs(:create_dm_channel).returns({"id" => "channel-1"})
      @api.expects(:create_message).with do |_channel, payload|
        payload[:embeds].first[:url] == "https://#{Rails.configuration.app.domain}/ships/carrack"
      end

      deliver
    end

    test "says why the reader is getting a DM" do
      @api.stubs(:create_dm_channel).returns({"id" => "channel-1"})
      @api.expects(:create_message).with do |_channel, payload|
        payload[:embeds].first.dig(:footer, :text) == I18n.t("discord.direct_message.footer")
      end

      deliver
    end

    test "sends nothing when the reader has no linked Discord account" do
      @user.omniauth_connections.destroy_all
      @api.expects(:create_dm_channel).never

      refute deliver
    end

    test "sends nothing without a bot token" do
      ::Discord::ApiClient.stubs(:configured?).returns(false)
      @api.expects(:create_dm_channel).never

      refute deliver
    end

    # The reader's Discord privacy settings are not something a retry changes.
    test "a reader who cannot be DMed is not an error to retry" do
      @api.stubs(:create_dm_channel).raises(::Discord::ApiClient::Error.new(403, "Cannot send messages to this user"))

      assert_nothing_raised { refute deliver }
    end

    test "an account unlinked between queueing and sending is not an error either" do
      @api.stubs(:create_dm_channel).raises(::Discord::ApiClient::Error.new(404, "Unknown User"))

      assert_nothing_raised { refute deliver }
    end

    test "a rate limit is left for the job to retry" do
      @api.stubs(:create_dm_channel).raises(::Discord::ApiClient::Error.new(429, "Too Many Requests"))

      assert_raises(::Discord::ApiClient::Error) { deliver }
    end

    test "an outage is left for the job to retry" do
      @api.stubs(:create_dm_channel).raises(::Discord::ApiClient::Error.new(503, "Service Unavailable"))

      assert_raises(::Discord::ApiClient::Error) { deliver }
    end

    test "deliverable? reports whether a DM has anywhere to go" do
      assert ::Discord::DirectMessage.deliverable?(@user)

      @user.omniauth_connections.destroy_all

      refute ::Discord::DirectMessage.deliverable?(@user.reload)
    end
  end
end
