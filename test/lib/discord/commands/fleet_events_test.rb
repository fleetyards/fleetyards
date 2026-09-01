# frozen_string_literal: true

require "test_helper"
require "discord/commands/fleet_events"

module Discord
  module Commands
    class FleetEventsTest < ActiveSupport::TestCase
      setup do
        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @user = create(:user)
        create(:omniauth_connection, user: @user, provider: "discord", uid: "member-uid")
        @fleet.fleet_memberships
          .create!(user: @user, fleet_role: @fleet.fleet_roles.find_by(name: "Member"))
          .update!(aasm_state: "accepted")
      end

      def call(guild_id: "guild-1", discord_user_id: "member-uid")
        ::Discord::Commands::FleetEvents.new(guild_id: guild_id, discord_user_id: discord_user_id).call
      end

      def event(**attributes)
        create(:fleet_event, :open, fleet: @fleet, **attributes)
      end

      # Slots hang off a team, not off the event: FleetEventSlot#slottable is
      # polymorphic and FleetEvent#slots collects across teams and ships.
      def team_with_slots(event, count)
        team = create(:fleet_event_team, fleet_event: event)
        count.times { create(:fleet_event_slot, slottable: team) }
        team
      end

      def accepted_member
        member = create(:user)
        @fleet.fleet_memberships
          .create!(user: member, fleet_role: @fleet.fleet_roles.find_by(name: "Member"))
          .tap { |membership| membership.update!(aasm_state: "accepted") }
      end

      test "lists an upcoming event" do
        event(title: "Strike Op", starts_at: 2.days.from_now)

        assert_includes call[:content], "Strike Op"
      end

      test "links the event and the fleet's event page" do
        strike = event(title: "Strike Op")

        content = call[:content]

        assert_includes content, "/fleets/#{@fleet.slug}/events/#{strike.slug}/"
        assert_includes content, "/fleets/#{@fleet.slug}/events/"
      end

      # Discord renders this in the reader's own timezone, which is the only
      # correct answer for a fleet spread across several.
      test "the start time is a Discord timestamp, not a rendered date" do
        strike = event(starts_at: 2.days.from_now)

        assert_includes call[:content], "<t:#{strike.starts_at.to_i}:f>"
      end

      test "reads soonest first" do
        event(title: "Later Op", starts_at: 5.days.from_now)
        event(title: "Sooner Op", starts_at: 2.days.from_now)

        content = call[:content]

        assert_operator content.index("Sooner Op"), :<, content.index("Later Op")
      end

      test "a past event is not upcoming" do
        event(title: "Old Op", starts_at: 2.days.ago)

        assert_equal I18n.t("discord.commands.fleet.events.none"), call[:content]
      end

      # Listing a draft in Discord publishes it in every sense that matters.
      test "a draft is not listed" do
        create(:fleet_event, fleet: @fleet, title: "Secret Op", starts_at: 2.days.from_now, status: "draft")

        assert_equal I18n.t("discord.commands.fleet.events.none"), call[:content]
      end

      test "a cancelled event is not listed" do
        create(:fleet_event, :cancelled, fleet: @fleet, title: "Called Off", starts_at: 2.days.from_now)

        assert_equal I18n.t("discord.commands.fleet.events.none"), call[:content]
      end

      test "an archived event is not listed" do
        event(title: "Archived Op", starts_at: 2.days.from_now).update!(archived_at: Time.current)

        assert_equal I18n.t("discord.commands.fleet.events.none"), call[:content]
      end

      test "reports how many slots are open" do
        team_with_slots(event(title: "Strike Op"), 3)

        assert_includes call[:content], I18n.t("discord.event_availability.slots", open: 3, total: 3)
      end

      test "a taken slot is not counted as open" do
        strike = event(title: "Strike Op")
        team = team_with_slots(strike, 3)
        create(:fleet_event_signup,
          fleet_event: strike,
          fleet_event_slot: team.fleet_event_slots.first,
          fleet_membership: accepted_member)

        assert_includes call[:content], I18n.t("discord.event_availability.slots", open: 2, total: 3)
      end

      # "0 of 0 slots open" reads like a full event, which is the opposite of
      # true.
      test "an event without slots reports signups instead" do
        strike = event(title: "Strike Op")
        create(:fleet_event_signup, fleet_event: strike, fleet_event_slot: nil, fleet_membership: accepted_member)

        content = call[:content]

        assert_includes content, I18n.t("discord.event_availability.signups", count: 1)
        assert_not_includes content, I18n.t("discord.event_availability.slots", open: 0, total: 0)
      end

      # A weekly op would otherwise appear once, on the date the series started.
      test "a recurring series is listed by occurrence" do
        event(title: "Weekly Op",
          starts_at: 2.days.from_now,
          recurring: true,
          recurrence_interval: "weekly")

        assert_equal ::Discord::Commands::FleetEvents::MAX_EVENTS, call[:content].scan("Weekly Op").size
      end

      test "a recurring occurrence keeps the parent's time of day on its own date" do
        starts_at = 2.days.from_now.change(hour: 19, min: 30)
        event(title: "Weekly Op", starts_at: starts_at, recurring: true, recurrence_interval: "weekly")

        assert_includes call[:content], "<t:#{(starts_at + 1.week).to_i}:f>"
      end

      test "an occurrence with its own title uses it" do
        weekly = event(title: "Weekly Op",
          starts_at: 2.days.from_now,
          recurring: true,
          recurrence_interval: "weekly")
        weekly.fleet_event_occurrence_states.create!(
          occurrence_date: (2.days.from_now + 1.week).to_date,
          title: "Special Edition"
        )

        assert_includes call[:content], "Special Edition"
      end

      # Only the overlay row knows a single occurrence of a live series is off.
      test "a cancelled occurrence is not listed" do
        weekly = event(title: "Weekly Op",
          starts_at: 2.days.from_now,
          recurring: true,
          recurrence_interval: "weekly")
        weekly.fleet_event_occurrence_states.create!(
          occurrence_date: 2.days.from_now.to_date,
          cancelled_at: Time.current
        )

        content = call[:content]

        assert_includes content, "Weekly Op"
        assert_not_includes content, "<t:#{weekly.starts_at.to_i}:f>"
      end

      test "caps the list" do
        (::Discord::Commands::FleetEvents::MAX_EVENTS + 2).times do |i|
          event(title: "Op #{i}", starts_at: (i + 2).days.from_now)
        end

        assert_equal ::Discord::Commands::FleetEvents::MAX_EVENTS, call[:content].scan("• [").size
      end

      test "says so when the server is not bound to a fleet" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: "guild-nope")[:content]
      end

      test "an unlinked Discord account is told where to link it" do
        assert_includes call(discord_user_id: "stranger-uid")[:content],
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections")
      end

      # The schedule is internal data: fleet:events:read is a member privilege,
      # and a guild can have guests.
      test "someone who only shares the Discord server cannot see the events" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")
        event(title: "Strike Op")

        assert_equal I18n.t("discord.commands.fleet.events.not_allowed"),
          call(discord_user_id: "guest-uid")[:content]
      end

      test "a member whose role has no read privilege cannot see the events" do
        @fleet.fleet_roles.find_by(name: "Member").update!(resource_access: [])
        event(title: "Strike Op")

        assert_equal I18n.t("discord.commands.fleet.events.not_allowed"), call[:content]
      end

      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call[:flags]
      end
    end
  end
end
