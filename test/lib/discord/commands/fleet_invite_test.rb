# frozen_string_literal: true

require "test_helper"
require "discord/commands/fleet_invite"

module Discord
  module Commands
    class FleetInviteTest < ActiveSupport::TestCase
      setup do
        Flipper.enable(:discord_fleet_commands)

        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @user = create(:user)
        create(:omniauth_connection, user: @user, provider: "discord", uid: "officer-uid")
        @fleet.fleet_memberships
          .create!(user: @user, fleet_role: role_named("Officer"))
          .update!(aasm_state: "accepted")
      end

      # Looked up by privilege rather than by rank position: the ranked order is
      # not what this test is about.
      def role_named(name)
        @fleet.fleet_roles.find_by(name: name)
      end

      def call(guild_id: "guild-1", discord_user_id: "officer-uid", options: {})
        ::Discord::Commands::FleetInvite.new(
          guild_id: guild_id,
          discord_user_id: discord_user_id,
          options: options
        ).call
      end

      test "creates an invite link for the guild's fleet" do
        content = call[:content]

        invite = @fleet.fleet_invite_urls.sole

        assert_includes content, invite.url
        assert_equal @user.id, invite.user_id
      end

      test "names the fleet the link belongs to" do
        assert_includes call[:content], "Test Wing"
      end

      # FleetInviteUrl#use puts the new membership straight into `requested`, so
      # the answer must not read as "they are in".
      test "says the link still needs accepting" do
        assert_includes call[:content], I18n.t("discord.commands.fleet.invite.needs_approval")
      end

      test "passes the limit through" do
        call(options: {"limit" => 5})

        assert_equal 5, @fleet.fleet_invite_urls.sole.limit
      end

      test "an unlimited link is the default" do
        call

        invite = @fleet.fleet_invite_urls.sole

        assert_nil invite.limit
        assert_nil invite.expires_after
      end

      test "expires_in is turned into a moment" do
        freeze_time do
          call(options: {"expires_in" => "24h"})

          assert_equal 24.hours.from_now, @fleet.fleet_invite_urls.sole.expires_after
        end
      end

      test "never means no expiry" do
        call(options: {"expires_in" => "never"})

        assert_nil @fleet.fleet_invite_urls.sole.expires_after
      end

      # Zero passes the model's own validation and is then excluded by
      # FleetInviteUrl.active, so it would hand out a link that is dead on
      # arrival.
      test "a limit of zero is refused rather than minted" do
        assert_equal I18n.t("discord.commands.fleet.invite.limit_too_low"), call(options: {"limit" => 0})[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      test "a negative limit is refused" do
        assert_equal I18n.t("discord.commands.fleet.invite.limit_too_low"), call(options: {"limit" => -3})[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      test "says so when the server is not bound to a fleet" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: "guild-nope")[:content]
      end

      test "says so when the command arrives without a guild" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: nil)[:content]
      end

      test "an unlinked Discord account is told where to link it" do
        assert_includes call(discord_user_id: "stranger-uid")[:content],
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections")
        assert_empty @fleet.fleet_invite_urls
      end

      # The fleet's own privileges decide, not anything Discord says about the
      # caller.
      test "a member without the privilege cannot mint a link" do
        member = create(:user)
        create(:omniauth_connection, user: member, provider: "discord", uid: "member-uid")
        @fleet.fleet_memberships
          .create!(user: member, fleet_role: role_named("Member"))
          .update!(aasm_state: "accepted")

        assert_equal I18n.t("discord.commands.fleet.invite.not_allowed"), call(discord_user_id: "member-uid")[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      test "someone who only shares the Discord server cannot mint a link" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        assert_equal I18n.t("discord.commands.fleet.invite.not_allowed"), call(discord_user_id: "guest-uid")[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      # An officer whose membership is not accepted yet has a role, and that role
      # carries the privilege -- the policy requires the membership to be
      # accepted, which is the whole reason this goes through the policy.
      test "an officer whose membership is not accepted cannot mint a link" do
        @fleet.fleet_memberships.find_by(user_id: @user.id).update!(aasm_state: "requested")

        assert_equal I18n.t("discord.commands.fleet.invite.not_allowed"), call[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      test "a discarded membership cannot mint a link" do
        @fleet.fleet_memberships.find_by(user_id: @user.id).discard

        assert_equal I18n.t("discord.commands.fleet.invite.not_allowed"), call[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      test "the command is refused while the flag is off" do
        Flipper.disable(:discord_fleet_commands)

        assert_equal I18n.t("discord.commands.disabled"), call[:content]
        assert_empty @fleet.fleet_invite_urls
      end

      # Visibility is fixed at the acknowledgement; RegistryTest and
      # DiscordInteractionsTest cover it where Discord actually reads it.
      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call[:flags]
      end
    end
  end
end
