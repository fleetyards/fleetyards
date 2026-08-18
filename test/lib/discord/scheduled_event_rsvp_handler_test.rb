# frozen_string_literal: true

require "test_helper"
require "discord/scheduled_event_rsvp_handler"

module Discord
  class ScheduledEventRsvpHandlerTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @user = create(:user)
      create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
      @event = create(:fleet_event, :open, fleet: @fleet, discord_event_id: "scheduled-1")
      @membership = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.fleet_roles.ranked.last)
      @membership.update!(aasm_state: "accepted")
    end

    class RecurringTest < ScheduledEventRsvpHandlerTest
      setup do
        @series = create(:fleet_event, :open, fleet: @fleet,
          starts_at: 1.week.from_now, recurring: true, recurrence_interval: "weekly")
        @occurrence_date = @series.occurrences(
          from: Time.current, to: 4.weeks.from_now
        ).second.to_date
        @series.fleet_event_occurrence_states.create!(
          occurrence_date: @occurrence_date, discord_event_id: "scheduled-occurrence-1"
        )
      end

      def handler
        ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-occurrence-1",
          discord_user_id: "discord-uid-1"
        )
      end

      test "resolves the event through the occurrence state" do
        result = handler.add!

        assert result.ok?, "expected ok, got #{result.status}: #{result.detail}"
        signup = @series.fleet_event_signups.find_by(fleet_membership: @membership)
        assert_equal @occurrence_date, signup.occurrence_date
        assert_equal "interested", signup.status
      end

      test "withdrawing only touches the occurrence it came from" do
        other_date = @series.occurrences(from: Time.current, to: 4.weeks.from_now).third.to_date
        other = @series.fleet_event_signups.create!(
          fleet_membership: @membership, fleet_event_slot: nil,
          occurrence_date: other_date, status: "interested"
        )
        handler.add!

        result = handler.remove!

        assert result.ok?, "expected ok, got #{result.status}: #{result.detail}"
        assert_equal "interested", other.reload.status
      end
    end

    class RemoveGuardTest < ScheduledEventRsvpHandlerTest
      def handler
        ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
      end

      test "keeps a confirmed signup that Discord never made" do
        signup = @event.fleet_event_signups.create!(
          fleet_membership: @membership, fleet_event_slot: nil, status: "confirmed"
        )

        result = handler.remove!

        assert result.skipped?, "expected skipped, got #{result.status}: #{result.detail}"
        assert_equal "confirmed", signup.reload.status
      end
    end

    class AddTest < ScheduledEventRsvpHandlerTest
      test "creates an event-level interested signup" do
        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )

        result = handler.add!
        assert result.ok?, "expected ok, got #{result.status}: #{result.detail}"
        signup = @event.fleet_event_signups.find_by(fleet_membership: @membership)
        assert_equal "interested", signup.status
        assert_nil signup.fleet_event_slot_id
      end

      test "leaves an existing event-level signup untouched" do
        @event.fleet_event_signups.create!(
          fleet_membership: @membership,
          fleet_event_slot: nil,
          status: "tentative"
        )

        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        result = handler.add!

        assert_equal :skipped, result.status
        assert_equal 1, @event.fleet_event_signups.where(fleet_membership: @membership).where.not(status: "withdrawn").count
        assert_equal "tentative", @event.fleet_event_signups.find_by(fleet_membership: @membership).status
      end

      test "leaves an existing slot-bound signup untouched" do
        team = create(:fleet_event_team, fleet_event: @event)
        slot = create(:fleet_event_slot, slottable: team)
        @event.fleet_event_signups.create!(
          fleet_membership: @membership,
          fleet_event_slot: slot,
          status: "confirmed"
        )

        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        result = handler.add!

        assert_equal :skipped, result.status
        assert_equal "confirmed", @event.fleet_event_signups.find_by(fleet_membership: @membership).status
      end

      test "skips when the user has no Discord connection" do
        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "unknown"
        )
        assert_equal :skipped, handler.add!.status
      end

      test "skips when the guild id doesn't match the fleet binding" do
        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "wrong-guild",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        assert_equal :skipped, handler.add!.status
      end

      test "skips when the user isn't an accepted member" do
        @membership.update!(aasm_state: "invited")
        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        assert_equal :skipped, handler.add!.status
      end
    end

    class RemoveTest < ScheduledEventRsvpHandlerTest
      test "withdraws the interested signup a Discord RSVP created" do
        signup = @event.fleet_event_signups.create!(
          fleet_membership: @membership,
          fleet_event_slot: nil,
          status: "interested"
        )

        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        assert handler.remove!.ok?
        assert_equal "withdrawn", signup.reload.status
      end

      test "is a no-op when nothing is signed up" do
        handler = ::Discord::ScheduledEventRsvpHandler.new(
          guild_id: "guild-1",
          scheduled_event_id: "scheduled-1",
          discord_user_id: "discord-uid-1"
        )
        assert_equal :skipped, handler.remove!.status
      end
    end
  end
end
