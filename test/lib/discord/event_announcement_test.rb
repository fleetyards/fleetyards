# frozen_string_literal: true

require "test_helper"
require "discord/event_announcement"

module Discord
  class EventAnnouncementTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
      @event = create(:fleet_event, :open, fleet: @fleet)
      ApiClient.stubs(:configured?).returns(true)
    end

    def hold_to(*squadrons)
      @event.update!(visibility: "squadron", fleet_squadrons: squadrons)
    end

    test "a fleet-wide event goes to the fleet's announcement channel" do
      @setting.update!(discord_announcement_channel_id: "111111111111111111")
      api = mock
      api.expects(:create_message).with("111111111111111111", {content: "hello", allowed_mentions: {parse: []}})
      ApiClient.stubs(:new).returns(api)

      EventAnnouncement.new(@event).deliver("hello")
    end

    test "a fleet-wide event falls back to the webhook when no channel is picked" do
      @setting.update!(discord_webhook_url: "https://discord.com/api/webhooks/1/token")

      assert_equal [WebhookPost], EventAnnouncement.new(@event).targets.map(&:class)
    end

    test "the channel wins over the webhook" do
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )

      assert_equal [ChannelPost], EventAnnouncement.new(@event).targets.map(&:class)
    end

    test "without a bot token the channel is unusable and the webhook still posts" do
      ApiClient.stubs(:configured?).returns(false)
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )

      assert_equal [WebhookPost], EventAnnouncement.new(@event).targets.map(&:class)
    end

    test "a squadron event goes to each distinct squadron channel" do
      hold_to(
        create(:fleet_squadron, fleet: @fleet, name: "Alpha", discord_channel_id: "222222222222222222"),
        create(:fleet_squadron, fleet: @fleet, name: "Bravo", discord_channel_id: "333333333333333333"),
        create(:fleet_squadron, fleet: @fleet, name: "Charlie", discord_channel_id: "222222222222222222"),
        create(:fleet_squadron, fleet: @fleet, name: "Delta", team: true, discord_channel_id: "444444444444444444")
      )
      api = mock
      api.expects(:create_message).with("222222222222222222", anything).once
      api.expects(:create_message).with("333333333333333333", anything).once
      api.expects(:create_message).with("444444444444444444", anything).once
      ApiClient.stubs(:new).returns(api)

      EventAnnouncement.new(@event).deliver("hello")
    end

    # The fleet's channel and webhook are read by the whole fleet.
    test "a squadron event never falls back to the fleet's channel or webhook" do
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )
      hold_to(create(:fleet_squadron, fleet: @fleet))

      assert_empty EventAnnouncement.new(@event).targets
      assert_not EventAnnouncement.deliverable?(@event)
    end

    test "a deleted channel posts nothing and does not raise" do
      @setting.update!(discord_announcement_channel_id: "111111111111111111")
      api = mock
      api.expects(:create_message).raises(ApiClient::Error.new(404, '{"code": 10003}'))
      ApiClient.stubs(:new).returns(api)

      assert_nothing_raised { EventAnnouncement.new(@event).deliver("hello") }
    end

    test "a rate limit is raised so the job retries" do
      @setting.update!(discord_announcement_channel_id: "111111111111111111")
      api = mock
      api.expects(:create_message).raises(ApiClient::Error.new(429, "slow down"))
      ApiClient.stubs(:new).returns(api)

      assert_raises(ApiClient::Error) { EventAnnouncement.new(@event).deliver("hello") }
    end
  end
end
