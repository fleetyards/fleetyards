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
      test "withdraws the existing signup" do
        signup = @event.fleet_event_signups.create!(
          fleet_membership: @membership,
          fleet_event_slot: nil,
          status: "confirmed"
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
