# frozen_string_literal: true

require "test_helper"
require "discord/commands/fleet"

module Discord
  module Commands
    class FleetTest < ActiveSupport::TestCase
      setup do
        # The factory defaults to a public fleet; most of what matters here is
        # what a *private* one exposes.
        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @user = create(:user)
        create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
        @membership = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.fleet_roles.ranked.last)
        @membership.update!(aasm_state: "accepted")
      end

      def call(guild_id: "guild-1", discord_user_id: "discord-uid-1")
        ::Discord::Commands::Fleet.new(guild_id: guild_id, discord_user_id: discord_user_id).call
      end

      test "shows the fleet bound to the guild" do
        embed = call[:embeds].first

        assert_equal "Test Wing", embed[:title]
        assert_includes embed[:url], "/fleets/#{@fleet.slug}"
      end

      test "says so when the server is not bound to a fleet" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: "guild-nope")[:content]
      end

      test "says so when the command arrives without a guild" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: nil)[:content]
      end

      # Sharing a server is not membership: a guild can have guests, and only
      # the fleet's own privacy setting speaks for it.
      test "a non-member cannot see a fleet that is not public" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        payload = call(discord_user_id: "guest-uid")

        assert_nil payload[:embeds]
        assert_includes payload[:content], "Test Wing"
      end

      test "a non-member can see a public fleet" do
        # update_column, not update!: Fleet accepts nested attributes for
        # fleet_memberships, so a normal save re-validates the loaded membership
        # and fails on something this test is not about.
        @fleet.update_column(:public_fleet, true)
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        assert_equal "Test Wing", call(discord_user_id: "guest-uid")[:embeds].first[:title]
      end

      test "a Discord user with no linked account is treated as a guest" do
        payload = call(discord_user_id: "unlinked-uid")

        assert_nil payload[:embeds]
      end

      test "a pending membership does not count as membership" do
        @membership.update!(aasm_state: "invited")

        assert_nil call[:embeds]
      end

      test "counts the accepted members" do
        fields = call[:embeds].first[:fields].to_h { |field| [field[:name], field[:value]] }

        assert_equal "1", fields[I18n.t("discord.commands.fleet.fields.members")]
      end

      test "counts only upcoming events" do
        create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now)
        create(:fleet_event, :open, fleet: @fleet, starts_at: 3.days.ago)

        fields = call[:embeds].first[:fields].to_h { |field| [field[:name], field[:value]] }

        assert_equal "1", fields[I18n.t("discord.commands.fleet.fields.upcoming_events")]
      end

      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call(guild_id: "guild-nope")[:flags]
      end
    end
  end
end
