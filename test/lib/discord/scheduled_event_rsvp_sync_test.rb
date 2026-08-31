# frozen_string_literal: true

require "test_helper"
require "discord/scheduled_event_rsvp_sync"

module Discord
  class ScheduledEventRsvpSyncTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
      @event = create(:fleet_event, :open, fleet: @fleet, discord_event_id: "scheduled-1")

      @user = create(:user)
      create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
      @membership = accept(@user)

      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:configured?).returns(true)
    end

    def accept(user)
      membership = @fleet.fleet_memberships.create!(user: user, fleet_role: @fleet.fleet_roles.ranked.last)
      membership.update!(aasm_state: "accepted")
      membership
    end

    def subscribers(*user_ids)
      user_ids.map { |id| {"user" => {"id" => id}} }
    end

    def sync(event_id: "scheduled-1")
      ::Discord::ScheduledEventRsvpSync.new(guild_id: "guild-1", discord_event_id: event_id, api: @api)
    end

    def signups
      @event.fleet_event_signups.where(fleet_membership: @membership).where.not(status: "withdrawn")
    end

    test "a new subscriber becomes an interested signup" do
      @api.expects(:list_guild_scheduled_event_users).returns(subscribers("discord-uid-1"))

      result = sync.run!

      assert_equal 1, result.added
      assert_equal "interested", signups.first.status
    end

    test "a new subscriber is recorded so the next poll is a no-op" do
      @api.stubs(:list_guild_scheduled_event_users).returns(subscribers("discord-uid-1"))

      sync.run!
      second = sync.run!

      assert_equal 0, second.added
      assert_equal 1, signups.count
    end

    test "a subscriber who unsubscribes has their signup withdrawn" do
      @api.stubs(:list_guild_scheduled_event_users).returns(subscribers("discord-uid-1"))
      sync.run!

      @api.stubs(:list_guild_scheduled_event_users).returns([])
      result = sync.run!

      assert_equal 1, result.removed
      assert_equal 0, signups.count
    end

    test "an unsubscribe drops the snapshot row as well" do
      @api.stubs(:list_guild_scheduled_event_users).returns(subscribers("discord-uid-1"))
      sync.run!

      @api.stubs(:list_guild_scheduled_event_users).returns([])
      sync.run!

      assert_equal 0, DiscordEventSubscription.for_event("scheduled-1").count
    end

    # The reason DiscordEventSubscription exists. A website signup looks exactly
    # like a Discord one to the handler, so a poll that diffed against signups
    # instead of against Discord's own state would withdraw it.
    test "a signup made on Fleetyards is untouched by a poll that never saw the user" do
      @event.fleet_event_signups.create!(
        fleet_membership: @membership, fleet_event_slot: nil, status: "interested"
      )
      @api.expects(:list_guild_scheduled_event_users).returns([])

      result = sync.run!

      assert_equal 0, result.removed
      assert_equal 1, signups.count
    end

    test "a subscriber with no linked Fleetyards account is still recorded" do
      @api.expects(:list_guild_scheduled_event_users).returns(subscribers("unlinked-uid"))

      sync.run!

      assert_equal ["unlinked-uid"], DiscordEventSubscription.user_ids_for("scheduled-1")
    end

    test "a subscriber with no linked account is not retried on the next poll" do
      @api.stubs(:list_guild_scheduled_event_users).returns(subscribers("unlinked-uid"))
      sync.run!

      assert_equal 0, sync.run!.added
    end

    # A deleted Discord event is not everyone changing their mind.
    test "a 404 drops the snapshot without withdrawing anything" do
      @api.stubs(:list_guild_scheduled_event_users).returns(subscribers("discord-uid-1"))
      sync.run!

      @api.stubs(:list_guild_scheduled_event_users)
        .raises(::Discord::ApiClient::Error.new(404, "Unknown Guild Scheduled Event"))

      assert_nil sync.run!
      assert_equal 0, DiscordEventSubscription.for_event("scheduled-1").count
      assert_equal 1, signups.count
    end

    test "any other API error is left to the caller" do
      @api.stubs(:list_guild_scheduled_event_users)
        .raises(::Discord::ApiClient::Error.new(500, "Internal Server Error"))

      assert_raises(::Discord::ApiClient::Error) { sync.run! }
    end

    test "reads every page of a subscriber list longer than one page" do
      first_page = Array.new(::Discord::ApiClient::SUBSCRIBER_PAGE_SIZE) do |i|
        {"user" => {"id" => "uid-#{i}"}}
      end
      @api.expects(:list_guild_scheduled_event_users)
        .with("guild-1", "scheduled-1", after: nil)
        .returns(first_page)
      @api.expects(:list_guild_scheduled_event_users)
        .with("guild-1", "scheduled-1", after: "uid-#{::Discord::ApiClient::SUBSCRIBER_PAGE_SIZE - 1}")
        .returns(subscribers("discord-uid-1"))

      result = sync.run!

      assert_equal ::Discord::ApiClient::SUBSCRIBER_PAGE_SIZE + 1, result.added
      assert_equal "interested", signups.first.status
    end

    test "does nothing without a bot token" do
      ::Discord::ApiClient.stubs(:configured?).returns(false)
      @api.expects(:list_guild_scheduled_event_users).never

      assert_nil sync.run!
    end

    test "does nothing for an event with no Discord id" do
      @api.expects(:list_guild_scheduled_event_users).never

      assert_nil sync(event_id: nil).run!
    end
  end
end
