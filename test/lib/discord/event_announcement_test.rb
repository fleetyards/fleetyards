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
      DeliverAnnouncementJob.clear
    end

    def hold_to(*squadrons)
      @event.update!(visibility: "squadron", fleet_squadrons: squadrons)
    end

    def targets
      EventAnnouncement.new(@event).targets
    end

    test "a fleet-wide event goes to the fleet" do
      @setting.update!(discord_announcement_channel_id: "111111111111111111")

      assert_equal [AnnouncementTarget.fleet], targets
    end

    test "a webhook alone is somewhere to post, without a bot or a guild" do
      ApiClient.stubs(:configured?).returns(false)
      @setting.update!(discord_guild_id: nil, discord_webhook_url: "https://discord.com/api/webhooks/1/token")

      assert_equal [AnnouncementTarget.fleet], targets
    end

    test "a fleet with neither a channel nor a webhook has nowhere to post" do
      assert_empty targets
      assert_not EventAnnouncement.deliverable?(@event)
    end

    test "a squadron event goes to each distinct squadron channel, teams included" do
      hold_to(
        create(:fleet_squadron, fleet: @fleet, name: "Alpha", discord_channel_id: "222222222222222222"),
        create(:fleet_squadron, fleet: @fleet, name: "Bravo", discord_channel_id: "333333333333333333"),
        create(:fleet_squadron, fleet: @fleet, name: "Charlie", discord_channel_id: "222222222222222222"),
        create(:fleet_squadron, fleet: @fleet, name: "Delta", team: true, discord_channel_id: "444444444444444444")
      )

      assert_equal %w[222222222222222222 333333333333333333 444444444444444444], targets.map(&:channel_id).sort
    end

    # The fleet's channel and webhook are read by the whole fleet.
    test "a squadron event never falls back to the fleet's channel or webhook" do
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )
      hold_to(create(:fleet_squadron, fleet: @fleet))

      assert_empty targets
    end

    test "a squadron channel needs the fleet's guild to be bound" do
      @setting.update!(discord_guild_id: nil)
      hold_to(create(:fleet_squadron, fleet: @fleet, discord_channel_id: "222222222222222222"))

      assert_empty targets
    end

    test "an officers' event goes to the officers' channel" do
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_officers_channel_id: "555555555555555555"
      )
      @event.update!(visibility: "officers")

      assert_equal [AnnouncementTarget.officers], targets
    end

    # Every member reads the fleet's channel and webhook.
    test "an officers' event without an officers' channel is not announced" do
      @setting.update!(
        discord_announcement_channel_id: "111111111111111111",
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )
      @event.update!(visibility: "officers")

      assert_empty targets
    end

    # A retry of one post must not repeat another that already landed.
    test "each target is posted by its own job" do
      hold_to(
        create(:fleet_squadron, fleet: @fleet, name: "Alpha", discord_channel_id: "222222222222222222"),
        create(:fleet_squadron, fleet: @fleet, name: "Bravo", discord_channel_id: "333333333333333333")
      )

      EventAnnouncement.new(@event).deliver("hello")

      assert_equal [
        [@fleet.id, "squadron", "222222222222222222", "hello", @event.id, false],
        [@fleet.id, "squadron", "333333333333333333", "hello", @event.id, false]
      ], DeliverAnnouncementJob.jobs.map { |job| job["args"] }.sort
    end
  end
end
