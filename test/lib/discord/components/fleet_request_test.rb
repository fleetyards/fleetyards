# frozen_string_literal: true

require "test_helper"

module Discord
  module Components
    class FleetRequestTest < ActiveSupport::TestCase
      setup do
        @fleet = create(:fleet, :private, name: "Test Wing")
        @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

        @officer = create(:user, username: "Officer")
        create(:omniauth_connection, user: @officer, provider: "discord", uid: "officer-uid")
        join(@fleet, @officer, "Officer", "accepted")

        @applicant = create(:user, username: "Newcomer")
        @request = join(@fleet, @applicant, "Member", "requested")
      end

      def join(fleet, user, role, state)
        fleet.fleet_memberships
          .create!(user: user, fleet_role: fleet.fleet_roles.find_by(name: role))
          .tap { |membership| membership.update!(aasm_state: state, requested_at: Time.zone.now) }
      end

      def click(decision = "accept", membership_id: @request.id, guild_id: "guild-1", discord_user_id: "officer-uid")
        FleetRequest.new(decision: decision, membership_id: membership_id, guild_id: guild_id, discord_user_id: discord_user_id).call
      end

      def disabled?(payload)
        payload[:components].first[:components].all? { |button| button[:disabled] }
      end

      test "accepting settles the request and updates the message" do
        result = click("accept")

        assert_equal "accepted", @request.reload.aasm_state
        assert_includes result[:update][:content], I18n.t("discord.join_request.accepted_by", officer: "Officer")
        assert disabled?(result[:update])
        assert_nil result[:reply]
      end

      test "declining declines it" do
        result = click("decline")

        assert_equal "declined", @request.reload.aasm_state
        assert_includes result[:update][:content], I18n.t("discord.join_request.declined_by", officer: "Officer")
      end

      test "the officer who clicked is recorded as the author of the change" do
        click("accept")

        assert_equal @officer.id, @request.reload.versions.last.author_id
      end

      test "a request answered meanwhile shows its current state instead" do
        @request.update!(aasm_state: "declined")

        result = click("accept")

        assert_equal "declined", @request.reload.aasm_state
        assert_includes result[:update][:content], I18n.t("discord.join_request.declined")
        assert disabled?(result[:update])
      end

      test "a second click keeps the name of the officer who answered first" do
        click("accept")
        second = create(:user, username: "Second")
        create(:omniauth_connection, user: second, provider: "discord", uid: "second-uid")
        join(@fleet, second, "Officer", "accepted")

        result = click("decline", discord_user_id: "second-uid")

        assert_equal "accepted", @request.reload.aasm_state
        assert_includes result[:update][:content], I18n.t("discord.join_request.accepted_by", officer: "Officer")
      end

      test "a member without the privilege is told privately and the message is left alone" do
        member = create(:user)
        create(:omniauth_connection, user: member, provider: "discord", uid: "member-uid")
        join(@fleet, member, "Member", "accepted")

        result = click("accept", discord_user_id: "member-uid")

        assert_equal "requested", @request.reload.aasm_state
        assert_nil result[:update]
        assert_equal I18n.t("discord.commands.fleet.requests.not_allowed"), result[:reply][:content]
      end

      # The privilege lives in the fleet, not in the channel: an officer who
      # stepped down keeps reading the officers' channel until Discord catches up.
      test "an officer whose membership has ended can no longer answer" do
        @fleet.fleet_memberships.find_by(user: @officer).discard!

        result = click("accept")

        assert_equal "requested", @request.reload.aasm_state
        assert_equal I18n.t("discord.commands.fleet.requests.not_allowed"), result[:reply][:content]
      end

      test "a clicker without a linked account is told where to link it" do
        result = click("accept", discord_user_id: "stranger-uid")

        assert_equal "requested", @request.reload.aasm_state
        assert_nil result[:update]
        assert_includes result[:reply][:content], "/settings/connections"
      end

      test "a server bound to no fleet settles nothing" do
        result = click("accept", guild_id: "other-guild")

        assert_equal "requested", @request.reload.aasm_state
        assert_equal I18n.t("discord.commands.fleet.not_bound"), result[:reply][:content]
      end

      # An officer of this server's fleet must not settle another fleet's
      # request by clicking a button that names it.
      test "a request of another fleet is not found, even for an officer of both" do
        other = create(:fleet, :private)
        join(other, @officer, "Officer", "accepted")
        foreign = join(other, create(:user), "Member", "requested")

        result = click("accept", membership_id: foreign.id)

        assert_equal "requested", foreign.reload.aasm_state
        assert disabled?(result[:update])
        assert_nil result[:update][:content]
        assert_equal I18n.t("discord.join_request.gone"), result[:reply][:content]
      end
    end
  end
end
