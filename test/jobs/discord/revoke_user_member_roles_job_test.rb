# frozen_string_literal: true

require "test_helper"

module Discord
  class RevokeUserMemberRolesJobTest < ActiveSupport::TestCase
    MEMBER_ROLE = "role-member"
    RANK_ROLE = "role-officer"
    FOREIGN_ROLE = "role-they-earned-elsewhere"
    UID = "discord-uid-1"

    setup do
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      @fleet = create(:fleet)
      @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1", discord_member_role_id: MEMBER_ROLE)
      @role = @fleet.fleet_roles.ranked.last
      @role.update!(discord_role_id: RANK_ROLE)

      @user = create(:user)
      @connection = create(:omniauth_connection, user: @user, provider: "discord", uid: UID)
      @membership = @fleet.fleet_memberships.create!(user: @user, fleet_role: @role)
      @membership.update!(aasm_state: "accepted")

      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:new).returns(@api)
      ::Discord::RevokeUserMemberRolesJob.jobs.clear
    end

    test "unlinking Discord enqueues a revoke for the old uid" do
      @connection.destroy!

      assert_equal [[@user.id, UID]], ::Discord::RevokeUserMemberRolesJob.jobs.map { |job| job["args"] }
    end

    test "unlinking another provider enqueues nothing" do
      create(:omniauth_connection, user: @user, provider: "github", uid: "gh-1").destroy!

      assert_empty ::Discord::RevokeUserMemberRolesJob.jobs
    end

    test "removes the managed roles and leaves the rest" do
      @connection.destroy!
      @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, RANK_ROLE, FOREIGN_ROLE]})
      @api.expects(:add_guild_member_role).never
      @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-1", UID, RANK_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-1", UID, FOREIGN_ROLE).never

      ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID)
    end

    test "covers every fleet the member is in" do
      other_fleet = create(:fleet)
      other_fleet.create_fleet_notification_setting!(discord_guild_id: "guild-2", discord_member_role_id: "role-other")
      other = other_fleet.fleet_memberships.create!(user: @user, fleet_role: other_fleet.fleet_roles.ranked.last)
      other.update!(aasm_state: "accepted")
      @connection.destroy!

      @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE]})
      @api.stubs(:get_guild_member).with("guild-2", UID).returns({"roles" => ["role-other"]})
      @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE)
      @api.expects(:remove_guild_member_role).with("guild-2", UID, "role-other")

      ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID)
    end

    test "skips a fleet with no Discord server" do
      @fleet.fleet_notification_setting.update!(discord_guild_id: nil)
      @connection.destroy!
      @api.expects(:get_guild_member).never

      ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID)
    end

    test "does nothing once the same account is linked again" do
      @connection.destroy!
      create(:omniauth_connection, user: @user, provider: "discord", uid: UID)
      @api.expects(:get_guild_member).never

      ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID)
    end

    test "one fleet's permanent error does not stop the others" do
      other_fleet = create(:fleet)
      other_fleet.create_fleet_notification_setting!(discord_guild_id: "guild-2", discord_member_role_id: "role-other")
      other_fleet.fleet_memberships.create!(user: @user, fleet_role: other_fleet.fleet_roles.ranked.last)
      @connection.destroy!

      @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE]})
      @api.stubs(:get_guild_member).with("guild-2", UID).returns({"roles" => ["role-other"]})
      @api.stubs(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE).raises(::Discord::ApiClient::Error.new(400, "Bad Request"))
      @api.expects(:remove_guild_member_role).with("guild-2", UID, "role-other")

      assert_nothing_raised { ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID) }
    end

    test "a rate limit is left for the job to retry" do
      @connection.destroy!
      @api.stubs(:get_guild_member).raises(::Discord::ApiClient::Error.new(429, "Too Many Requests"))

      assert_raises(::Discord::ApiClient::Error) { ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID) }
    end

    test "does nothing without a bot token" do
      ::Discord::ApiClient.stubs(:configured?).returns(false)
      @connection.destroy!
      @api.expects(:get_guild_member).never

      ::Discord::RevokeUserMemberRolesJob.new.perform(@user.id, UID)
    end
  end
end
