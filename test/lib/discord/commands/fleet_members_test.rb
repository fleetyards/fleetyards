# frozen_string_literal: true

require "test_helper"
require "discord/commands/fleet_members"

module Discord
  module Commands
    class FleetMembersTest < ActiveSupport::TestCase
      setup do
        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @officer = create(:user, username: "Aendrax")
        create(:omniauth_connection, user: @officer, provider: "discord", uid: "officer-uid")
        accept(@officer, "Officer")
      end

      def role_named(name)
        @fleet.fleet_roles.find_by(name: name)
      end

      def accept(user, role = "Member")
        @fleet.fleet_memberships
          .create!(user: user, fleet_role: role_named(role))
          .tap { |membership| membership.update!(aasm_state: "accepted") }
      end

      def request(user, requested_at: Time.zone.now)
        @fleet.fleet_memberships
          .create!(user: user, fleet_role: role_named("Member"))
          .tap { |membership| membership.update!(aasm_state: "requested", requested_at: requested_at) }
      end

      def call(guild_id: "guild-1", discord_user_id: "officer-uid", options: {})
        ::Discord::Commands::FleetMembers.new(
          guild_id: guild_id,
          discord_user_id: discord_user_id,
          options: options
        ).call
      end

      test "lists the accepted members" do
        accept(create(:user, username: "Bravo"))

        content = call[:content]

        assert_includes content, "Aendrax"
        assert_includes content, "Bravo"
      end

      test "names each member's role" do
        assert_includes call[:content], "Officer"
      end

      test "reads alphabetically, so a name can be found" do
        accept(create(:user, username: "Zulu"))
        accept(create(:user, username: "Bravo"))

        content = call[:content]

        assert_operator content.index("Aendrax"), :<, content.index("Bravo")
        assert_operator content.index("Bravo"), :<, content.index("Zulu")
      end

      test "links the fleet's member page" do
        assert_includes call[:content], "/fleets/#{@fleet.slug}/members/"
      end

      test "a pending request is not in the roster" do
        request(create(:user, username: "Waiting"))

        assert_not_includes call[:content], "Waiting"
      end

      test "a discarded membership is not in the roster" do
        accept(create(:user, username: "Gone")).discard

        assert_not_includes call[:content], "Gone"
      end

      test "the pending filter lists the join requests" do
        request(create(:user, username: "Waiting"))

        content = call(options: {"filter" => "pending"})[:content]

        assert_includes content, "Waiting"
        assert_not_includes content, "Aendrax"
      end

      # The queue is worked through oldest first, so that is how it reads.
      test "the pending list reads oldest first" do
        request(create(:user, username: "Newer"), requested_at: 1.hour.ago)
        request(create(:user, username: "Older"), requested_at: 3.days.ago)

        content = call(options: {"filter" => "pending"})[:content]

        assert_operator content.index("Older"), :<, content.index("Newer")
      end

      test "the pending list says how long each request has waited" do
        request(create(:user, username: "Waiting"), requested_at: 3.days.ago)

        assert_includes call(options: {"filter" => "pending"})[:content],
          I18n.t("discord.commands.fleet.members.waiting", time: "3 days")
      end

      test "an empty queue says so rather than showing an empty list" do
        assert_equal I18n.t("discord.commands.fleet.members.no_requests"),
          call(options: {"filter" => "pending"})[:content]
      end

      test "says so when the server is not bound to a fleet" do
        assert_equal I18n.t("discord.commands.fleet.not_bound"), call(guild_id: "guild-nope")[:content]
      end

      test "an unlinked Discord account is told where to link it" do
        assert_includes call(discord_user_id: "stranger-uid")[:content],
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections")
      end

      # A roster is personal data, so the fleet's own privilege decides -- not
      # the fact that someone is in the Discord server.
      test "a member without the read privilege cannot see the roster" do
        stripped = role_named("Member")
        stripped.update!(resource_access: [])

        member = create(:user, username: "Plain")
        create(:omniauth_connection, user: member, provider: "discord", uid: "member-uid")
        accept(member, "Member")

        assert_equal I18n.t("discord.commands.fleet.members.not_allowed"),
          call(discord_user_id: "member-uid")[:content]
      end

      test "someone who only shares the Discord server cannot see the roster" do
        create(:omniauth_connection, user: create(:user), provider: "discord", uid: "guest-uid")

        assert_equal I18n.t("discord.commands.fleet.members.not_allowed"),
          call(discord_user_id: "guest-uid")[:content]
      end

      test "an officer whose membership is not accepted cannot see the roster" do
        @fleet.fleet_memberships.find_by(user_id: @officer.id).update!(aasm_state: "requested")

        assert_equal I18n.t("discord.commands.fleet.members.not_allowed"), call[:content]
      end

      test "caps a long roster and says how many were left out" do
        # The officer from the setup is already on the roster, so the overflow is
        # counted from the total rather than from the number added here.
        added = ::Discord::Commands::FleetMembers::MAX_MEMBERS + 2
        added.times { |i| accept(create(:user, username: "Member#{i.to_s.rjust(2, "0")}")) }
        omitted = added + 1 - ::Discord::Commands::FleetMembers::MAX_MEMBERS

        assert_includes call[:content], I18n.t("discord.commands.fleet.members.more", count: omitted)
      end

      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call[:flags]
      end
    end
  end
end
