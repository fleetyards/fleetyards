# frozen_string_literal: true

require "test_helper"
require "discord/member_role_sync"

module Discord
  class MemberRoleSyncTest < ActiveSupport::TestCase
    MEMBER_ROLE = "role-member"
    RANK_ROLE = "role-officer"
    FOREIGN_ROLE = "role-they-earned-elsewhere"

    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(
        discord_guild_id: "guild-1",
        discord_member_role_id: MEMBER_ROLE
      )

      @user = create(:user)
      create(:omniauth_connection, user: @user, provider: "discord", uid: "discord-uid-1")

      @role = @fleet.fleet_roles.ranked.last
      @membership = @fleet.fleet_memberships.create!(user: @user, fleet_role: @role)
      @membership.update!(aasm_state: "accepted")

      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:configured?).returns(true)
    end

    def sync
      ::Discord::MemberRoleSync.new(@membership.reload, api: @api)
    end

    def member_has(*role_ids)
      @api.stubs(:get_guild_member).returns({"roles" => role_ids})
    end

    test "gives an accepted member the member role" do
      member_has
      @api.expects(:add_guild_member_role).with("guild-1", "discord-uid-1", MEMBER_ROLE)

      result = sync.run!

      assert result.ok?
      assert_equal [MEMBER_ROLE], result.added
    end

    test "adds nothing when the member already has the role" do
      member_has(MEMBER_ROLE)
      @api.expects(:add_guild_member_role).never
      @api.expects(:remove_guild_member_role).never

      assert_empty sync.run!.added
    end

    test "gives the role mapped to the member's rank" do
      @role.update!(discord_role_id: RANK_ROLE)
      member_has(MEMBER_ROLE)
      @api.expects(:add_guild_member_role).with("guild-1", "discord-uid-1", RANK_ROLE)

      assert_equal [RANK_ROLE], sync.run!.added
    end

    test "takes the roles away when the member is no longer accepted" do
      @membership.update!(aasm_state: "declined")
      member_has(MEMBER_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-1", "discord-uid-1", MEMBER_ROLE)

      assert_equal [MEMBER_ROLE], sync.run!.removed
    end

    test "takes the roles away when the membership is discarded" do
      @membership.update!(discarded_at: Time.current)
      member_has(MEMBER_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-1", "discord-uid-1", MEMBER_ROLE)

      assert_equal [MEMBER_ROLE], sync.run!.removed
    end

    test "swaps the rank role when the member is promoted" do
      other = @fleet.fleet_roles.ranked.first
      other.update!(discord_role_id: "role-admin")
      @role.update!(discord_role_id: RANK_ROLE)
      @membership.update!(fleet_role: other)

      member_has(MEMBER_ROLE, RANK_ROLE)
      @api.expects(:add_guild_member_role).with("guild-1", "discord-uid-1", "role-admin")
      @api.expects(:remove_guild_member_role).with("guild-1", "discord-uid-1", RANK_ROLE)

      sync.run!
    end

    # The invariant. A colour role, a game role, a moderator role -- none of
    # them are ours to remove.
    test "never removes a role the fleet did not put under our control" do
      @membership.update!(aasm_state: "declined")
      member_has(MEMBER_ROLE, FOREIGN_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-1", "discord-uid-1", MEMBER_ROLE)

      result = sync.run!

      assert_equal [MEMBER_ROLE], result.removed
      assert_not_includes result.removed, FOREIGN_ROLE
    end

    test "managed roles are exactly what the fleet configured" do
      @role.update!(discord_role_id: RANK_ROLE)

      assert_equal [MEMBER_ROLE, RANK_ROLE].sort, sync.managed_role_ids.sort
    end

    test "does nothing when the fleet mapped no roles at all" do
      @setting.update!(discord_member_role_id: nil)
      @api.expects(:get_guild_member).never

      refute sync.runnable?
      assert_equal :not_runnable, sync.run!.code
    end

    test "does nothing for a member with no linked Discord account" do
      @user.omniauth_connections.destroy_all
      @api.expects(:get_guild_member).never

      refute ::Discord::MemberRoleSync.new(@membership.reload, api: @api).runnable?
    end

    test "does nothing without a bot token" do
      ::Discord::ApiClient.stubs(:configured?).returns(false)

      refute sync.runnable?
    end

    # Plenty of fleet members never join the fleet's Discord.
    test "a member who is not in the guild is not a failure" do
      @api.stubs(:get_guild_member).raises(::Discord::ApiClient::Error.new(404, "Unknown Member"))
      @api.expects(:add_guild_member_role).never

      assert_equal :not_in_guild, sync.run!.code
    end

    # Almost always the pre-Manage-Roles install mask, or a role above the
    # bot's own. A retry changes neither.
    test "a forbidden role change is reported rather than retried" do
      member_has
      @api.stubs(:add_guild_member_role).raises(::Discord::ApiClient::Error.new(403, "Missing Permissions"))

      assert_nothing_raised do
        assert_equal :forbidden, sync.run!.code
      end
    end

    test "a rate limit is left for the job to retry" do
      member_has
      @api.stubs(:add_guild_member_role).raises(::Discord::ApiClient::Error.new(429, "Too Many Requests"))

      assert_raises(::Discord::ApiClient::Error) { sync.run! }
    end
  end
end
