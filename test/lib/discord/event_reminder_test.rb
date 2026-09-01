# frozen_string_literal: true

require "test_helper"
require "discord/event_reminder"

module Discord
  class EventReminderTest < ActiveSupport::TestCase
    Builder = Struct.new(:content, :allowed_mentions)

    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(
        discord_webhook_url: "https://discord.com/api/webhooks/1/token"
      )
      @event = create(:fleet_event, :open, fleet: @fleet, title: "Strike Op", starts_at: 25.minutes.from_now)

      @builder = Builder.new
      @client = mock("Discordrb::Webhooks::Client")
      @client.stubs(:execute).yields(@builder)
      Discordrb::Webhooks::Client.stubs(:new).returns(@client)
    end

    def post(occurrence_date: nil)
      ::Discord::EventReminder.new(event: @event, occurrence_date: occurrence_date).run
      @builder.content
    end

    def team_with_slots(count)
      team = create(:fleet_event_team, fleet_event: @event)
      count.times { create(:fleet_event_slot, slottable: team) }
      team
    end

    def accepted_member
      user = create(:user)
      membership = @fleet.fleet_memberships.create!(user: user, fleet_role: @fleet.fleet_roles.ranked.last)
      membership.update!(aasm_state: "accepted")
      membership
    end

    test "names the event and links it" do
      content = post

      assert_includes content, "Strike Op"
      assert_includes content, "/fleets/#{@fleet.slug}/events/#{@event.slug}"
    end

    test "says how long until it starts" do
      assert_includes post, I18n.t("discord.event_reminder.starts_in", count: 25)
    end

    test "an event already starting says so rather than counting down past zero" do
      @event.update_column(:starts_at, 10.seconds.ago)

      assert_includes post, I18n.t("discord.event_reminder.starting_now")
    end

    # The whole point of the message: Discord's own reminder cannot know this.
    test "reports how many slots are open" do
      team_with_slots(14)

      assert_includes post, I18n.t("discord.event_availability.slots", open: 14, total: 14)
    end

    test "a taken slot is not counted as open" do
      team = team_with_slots(3)
      create(:fleet_event_signup,
        fleet_event: @event,
        fleet_event_slot: team.fleet_event_slots.first,
        fleet_membership: accepted_member)

      assert_includes post, I18n.t("discord.event_availability.slots", open: 2, total: 3)
    end

    test "a withdrawn signup frees its slot again" do
      team = team_with_slots(3)
      signup = create(:fleet_event_signup,
        fleet_event: @event,
        fleet_event_slot: team.fleet_event_slots.first,
        fleet_membership: accepted_member)
      signup.update!(status: "withdrawn")

      assert_includes post, I18n.t("discord.event_availability.slots", open: 3, total: 3)
    end

    # "0 of 0 slots open" reads like a full event, which is the opposite of true.
    test "an event without slots reports signups instead" do
      create(:fleet_event_signup,
        fleet_event: @event,
        fleet_event_slot: nil,
        fleet_membership: accepted_member)

      content = post

      assert_includes content, I18n.t("discord.event_availability.signups", count: 1)
      assert_not_includes content, I18n.t("discord.event_availability.slots", open: 0, total: 0)
    end

    test "an event with neither slots nor signups still announces itself" do
      content = post

      assert_includes content, "Strike Op"
      assert_includes content, I18n.t("discord.event_reminder.starts_in", count: 25)
    end

    # Nothing to post to is not an error.
    test "posts nothing when the fleet has no webhook" do
      @setting.update!(discord_webhook_url: nil)
      @client.expects(:execute).never

      ::Discord::EventReminder.new(event: @event).run
    end

    test "the global announcements webhook is never used for a fleet reminder" do
      @setting.update!(discord_webhook_url: nil)
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns("https://discord.com/api/webhooks/global/token")
      @client.expects(:execute).never

      ::Discord::EventReminder.new(event: @event).run
    end
  end
end
