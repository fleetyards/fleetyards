# frozen_string_literal: true

require "test_helper"
require "discord/commands/fleet_accept"
require "discord/commands/fleet_decline"

module Discord
  module Commands
    class FleetRequestDecisionTest < ActiveSupport::TestCase
      setup do
        Flipper.enable(:discord_fleet_commands)

        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @officer = create(:user)
        create(:omniauth_connection, user: @officer, provider: "discord", uid: "officer-uid")
        accept(@officer, "Officer")

        @applicant = create(:user, username: "Newcomer")
        @request = request(@applicant)
      end

      def role_named(name)
        @fleet.fleet_roles.find_by(name: name)
      end

      def accept(user, role = "Member")
        @fleet.fleet_memberships
          .create!(user: user, fleet_role: role_named(role))
          .tap { |membership| membership.update!(aasm_state: "accepted") }
      end

      def request(user)
        @fleet.fleet_memberships
          .create!(user: user, fleet_role: role_named("Member"))
          .tap { |membership| membership.update!(aasm_state: "requested", requested_at: Time.zone.now) }
      end

      def call(command, username: "Newcomer", guild_id: "guild-1", discord_user_id: "officer-uid")
        command.new(
          guild_id: guild_id,
          discord_user_id: discord_user_id,
          options: {"username" => username}
        ).call
      end

      test "accepting a request makes the applicant a member" do
        content = call(::Discord::Commands::FleetAccept)[:content]

        assert_equal "accepted", @request.reload.aasm_state
        assert_includes content, "Newcomer"
        assert_includes content, "Test Wing"
      end

      test "declining a request declines it" do
        call(::Discord::Commands::FleetDecline)

        assert_equal "declined", @request.reload.aasm_state
      end

      test "the officer is recorded as the author of the change" do
        call(::Discord::Commands::FleetAccept)

        assert_equal @officer.id, @request.reload.versions.last.author_id
      end

      test "a username is matched regardless of case" do
        call(::Discord::Commands::FleetAccept, username: "newcomer")

        assert_equal "accepted", @request.reload.aasm_state
      end

      test "a blank username asks for one" do
        assert_equal I18n.t("discord.commands.fleet.requests.missing_username"),
          call(::Discord::Commands::FleetAccept, username: " ")[:content]
      end

      test "someone with no request is said to have none" do
        assert_equal I18n.t("discord.commands.fleet.requests.no_request", username: "Nobody"),
          call(::Discord::Commands::FleetAccept, username: "Nobody")[:content]
      end

      # Two officers answering the same request is normal. AASM runs with
      # whiny_transitions off, so a second call would quietly return false and
      # read as a failure.
      test "a request that was already answered says so rather than failing" do
        call(::Discord::Commands::FleetAccept)

        content = call(::Discord::Commands::FleetAccept)[:content]

        assert_includes content, I18n.t("discord.commands.fleet.requests.not_pending",
          username: "Newcomer",
          url: "https://#{Rails.configuration.app.domain}/fleets/#{@fleet.slug}/members/")
        assert_equal "accepted", @request.reload.aasm_state
      end

      test "an accepted member cannot be declined through the command" do
        member = create(:user, username: "Settled")
        accept(member)

        call(::Discord::Commands::FleetDecline, username: "Settled")

        assert_equal "accepted", @fleet.fleet_memberships.find_by(user_id: member.id).aasm_state
      end

      test "a member without the privilege cannot answer requests" do
        plain = create(:user)
        create(:omniauth_connection, user: plain, provider: "discord", uid: "member-uid")
        accept(plain, "Member")

        assert_equal I18n.t("discord.commands.fleet.requests.not_allowed"),
          call(::Discord::Commands::FleetAccept, discord_user_id: "member-uid")[:content]
        assert_equal "requested", @request.reload.aasm_state
      end

      test "someone who only shares the Discord server cannot answer requests" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        assert_equal I18n.t("discord.commands.fleet.requests.not_allowed"),
          call(::Discord::Commands::FleetAccept, discord_user_id: "guest-uid")[:content]
        assert_equal "requested", @request.reload.aasm_state
      end

      test "an officer whose own membership is not accepted cannot answer requests" do
        @fleet.fleet_memberships.find_by(user_id: @officer.id).update!(aasm_state: "requested")

        assert_equal I18n.t("discord.commands.fleet.requests.not_allowed"),
          call(::Discord::Commands::FleetAccept)[:content]
        assert_equal "requested", @request.reload.aasm_state
      end

      # Otherwise the command tells anyone without the privilege whether a given
      # person has applied.
      test "the privilege is checked before the request is looked up" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        applied = call(::Discord::Commands::FleetAccept, discord_user_id: "guest-uid")[:content]
        never_applied = call(::Discord::Commands::FleetAccept, username: "Nobody", discord_user_id: "guest-uid")[:content]

        assert_equal applied, never_applied
      end

      test "says so when the server is not bound to a fleet" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"),
          call(::Discord::Commands::FleetAccept, guild_id: "guild-nope")[:content]
      end

      test "an unlinked Discord account is told where to link it" do
        assert_includes call(::Discord::Commands::FleetAccept, discord_user_id: "stranger-uid")[:content],
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections")
        assert_equal "requested", @request.reload.aasm_state
      end

      test "the command is refused while the flag is off" do
        Flipper.disable(:discord_fleet_commands)

        assert_equal I18n.t("discord.commands.disabled"), call(::Discord::Commands::FleetAccept)[:content]
        assert_equal "requested", @request.reload.aasm_state
      end

      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call(::Discord::Commands::FleetAccept)[:flags]
      end
    end
  end
end
