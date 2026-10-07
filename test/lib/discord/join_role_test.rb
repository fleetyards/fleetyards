# frozen_string_literal: true

require "test_helper"

module Discord
  class JoinRoleTest < ActiveSupport::TestCase
    GUILD = "100000000000000001"
    JOIN_ROLE = "300000000000000001"
    OTHER_ROLE = "300000000000000002"

    setup do
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      @admin = create(:user)
      @fleet = create(:fleet, admins: [@admin])
      @fleet.create_fleet_notification_setting!(discord_guild_id: GUILD, discord_join_role_id: JOIN_ROLE)
      @user = create(:user)
      create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")
      @api = mock("Discord::ApiClient")
    end

    def join_role
      JoinRole.new(@fleet.reload, api: @api)
    end

    def membership
      @fleet.fleet_memberships.kept.find_by(user: @user)
    end

    test "a player holding the role is seen as holding it" do
      @api.stubs(:get_guild_member).with(GUILD, "discord-uid-1").returns({"roles" => [OTHER_ROLE, JOIN_ROLE]})

      assert join_role.held_by?(@user)
    end

    test "a player Discord cannot find does not hold the role" do
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(404, "Unknown Member"))

      refute join_role.held_by?(@user)
    end

    test "a player Discord does not answer for in time does not hold the role" do
      @api.stubs(:get_guild_member).raises(Faraday::TimeoutError)

      refute join_role.held_by?(@user)
    end

    test "a player without a linked Discord account does not hold the role" do
      @api.expects(:get_guild_member).never

      refute join_role.held_by?(create(:user))
    end

    test "gaining the role makes the player a member with the default role" do
      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate membership, :accepted?
      assert_predicate membership, :discord_role_granted?
      assert_equal @fleet.default_member_role, membership.fleet_role
      assert Notification.exists?(user: @user, notification_type: "fleet_request_accepted")
      assert Notification.exists?(user: @admin, notification_type: "fleet_member_accepted")
    end

    test "gaining the role accepts an open request" do
      request = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      request.request!

      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate request.reload, :accepted?
      assert_predicate request, :discord_role_granted?
    end

    test "gaining the role accepts an officer's invitation without handing the membership to the role" do
      invitation = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      invitation.invite!

      join_role.apply(@user, [JOIN_ROLE])
      join_role.apply(@user, [])

      assert_predicate invitation.reload, :accepted?
      assert_predicate invitation, :kept?
      refute_predicate invitation, :discord_role_granted?
    end

    test "a player mid-way through asking to join is tried again on the next update" do
      @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)

      join_role.apply(@user, [JOIN_ROLE])

      refute FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "a quiet admission tells the player and the members' views but not the officers" do
      FleetVehiclesChannel.expects(:broadcast_to).with(@admin, anything).at_least_once
      FleetVehiclesChannel.stubs(:broadcast_to).with(@user, anything)

      join_role.apply(@user, [JOIN_ROLE], quiet: true)

      assert_predicate membership, :accepted?
      assert Notification.exists?(user: @user, notification_type: "fleet_request_accepted")
      refute Notification.exists?(user: @admin, notification_type: "fleet_member_accepted")
    end

    test "losing the role ends a membership the role created" do
      join_role.apply(@user, [JOIN_ROLE])

      join_role.apply(@user, [OTHER_ROLE])

      assert_nil membership
      assert_predicate @fleet.fleet_memberships.with_discarded.find_by(user: @user), :discarded?
    end

    test "losing the role keeps a membership an officer approved" do
      approved = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      approved.update!(aasm_state: "accepted")
      join_role.apply(@user, [JOIN_ROLE])

      join_role.apply(@user, [])

      assert_predicate approved.reload, :kept?
      refute_predicate approved, :discord_role_granted?
    end

    test "an update that leaves the role in place does not bring back a member who left" do
      join_role.apply(@user, [JOIN_ROLE])
      membership.discard

      join_role.apply(@user, [JOIN_ROLE, OTHER_ROLE])

      assert_nil membership
    end

    test "losing and regaining the role brings back a member who left" do
      join_role.apply(@user, [JOIN_ROLE])
      membership.discard

      join_role.apply(@user, [])
      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate membership, :accepted?
    end

    test "a fleet without a join role ignores role changes" do
      @fleet.fleet_notification_setting.update!(discord_join_role_id: nil)

      join_role.apply(@user, [JOIN_ROLE])

      assert_nil membership
    end

    test "a member update queues a job only for a linked player in a guild with a join role" do
      ApplyJoinRolesJob.jobs.clear

      JoinRole.member_changed("100000000000000099", "discord-uid-1")
      JoinRole.member_changed(GUILD, "discord-uid-unlinked")
      assert_empty ApplyJoinRolesJob.jobs

      JoinRole.member_changed(GUILD, "discord-uid-1")
      assert_equal [["discord-uid-1", GUILD]], ApplyJoinRolesJob.jobs.pluck("args")
    end
  end
end
