# frozen_string_literal: true

require "test_helper"
require "discord/announcement_target"

module Discord
  class AnnouncementTargetTest < ActiveSupport::TestCase
    GUILD = "900000000000000000"
    CHANNEL = "111111111111111111"

    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: GUILD)
      ApiClient.stubs(:configured?).returns(true)
      @api = mock("Discord::ApiClient")
      ApiClient.stubs(:new).returns(@api)
    end

    def channel_in(guild_id)
      @api.stubs(:get_channel).with(CHANNEL).returns({"id" => CHANNEL, "guild_id" => guild_id})
    end

    test "posts to a squadron channel in the fleet's guild without pinging anybody" do
      channel_in(GUILD)
      @api.expects(:create_message).with(CHANNEL, {content: "hello", allowed_mentions: {parse: []}})

      assert AnnouncementTarget.squadron(CHANNEL).deliver(@fleet, "hello")
    end

    # A channel id is only what somebody saved; it may point at another server.
    test "never posts to a channel of another guild" do
      channel_in("800000000000000000")
      @api.expects(:create_message).never

      assert_not AnnouncementTarget.squadron(CHANNEL).deliver(@fleet, "hello")
    end

    test "a deleted channel posts nothing and does not raise" do
      @api.stubs(:get_channel).raises(ApiClient::Error.new(404, '{"code": 10003}'))

      assert_not AnnouncementTarget.squadron(CHANNEL).deliver(@fleet, "hello")
    end

    test "a rate limit is raised so the job retries" do
      channel_in(GUILD)
      @api.expects(:create_message).raises(ApiClient::Error.new(429, "slow down"))

      assert_raises(ApiClient::Error) { AnnouncementTarget.squadron(CHANNEL).deliver(@fleet, "hello") }
    end

    test "the fleet's channel wins over its webhook" do
      @setting.update!(discord_announcement_channel_id: CHANNEL, discord_webhook_url: "https://discord.com/api/webhooks/1/token")
      channel_in(GUILD)
      @api.expects(:create_message)
      WebhookPost.any_instance.expects(:deliver).never

      assert AnnouncementTarget.fleet.deliver(@fleet, "hello")
    end

    # A fleet that set up both still hears about its events.
    test "the fleet falls back to its webhook when the bot cannot post in its channel" do
      @setting.update!(discord_announcement_channel_id: CHANNEL, discord_webhook_url: "https://discord.com/api/webhooks/1/token")
      @api.stubs(:get_channel).raises(ApiClient::Error.new(403, "missing access"))
      WebhookPost.any_instance.expects(:deliver).with("hello").returns(true)

      assert AnnouncementTarget.fleet.deliver(@fleet, "hello")
    end

    test "the fleet posts through its webhook without a bot" do
      ApiClient.stubs(:configured?).returns(false)
      @setting.update!(discord_announcement_channel_id: CHANNEL, discord_webhook_url: "https://discord.com/api/webhooks/1/token")
      @api.expects(:get_channel).never
      WebhookPost.any_instance.expects(:deliver).with("hello").returns(true)

      assert AnnouncementTarget.fleet.deliver(@fleet, "hello")
    end

    test "the job's arguments rebuild the same target" do
      target = AnnouncementTarget.squadron(CHANNEL)

      assert_equal target, AnnouncementTarget.new(*target.to_args)
    end
  end
end
