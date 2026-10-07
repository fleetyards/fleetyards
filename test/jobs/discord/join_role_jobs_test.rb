# frozen_string_literal: true

require "test_helper"

module Discord
  class JoinRoleJobsTest < ActiveSupport::TestCase
    GUILD = "100000000000000001"
    JOIN_ROLE = "300000000000000001"

    setup do
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      @admin = create(:user)
      @fleet = create(:fleet, admins: [@admin])
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: GUILD, discord_join_role_id: JOIN_ROLE)
      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:new).returns(@api)
      ApplyJoinRolesJob.jobs.clear
      SyncFleetJoinRoleJob.jobs.clear
    end

    def linked_user(uid)
      create(:user).tap { |user| create(:omniauth_connection, user:, provider: "discord", uid:) }
    end

    def member(uid, *roles)
      {"user" => {"id" => uid}, "roles" => roles}
    end

    def membership_of(user)
      @fleet.fleet_memberships.kept.find_by(user:)
    end

    test "linking Discord applies the join roles the player holds" do
      user = linked_user("uid-1")

      assert_equal [["uid-1"]], ApplyJoinRolesJob.jobs.pluck("args")

      @api.stubs(:get_guild_member).with(GUILD, "uid-1").returns({"roles" => [JOIN_ROLE]})
      ApplyJoinRolesJob.new.perform("uid-1")

      assert_predicate membership_of(user), :accepted?
    end

    test "leaving the guild ends a membership the role created" do
      user = linked_user("uid-1")
      JoinRole.new(@fleet).apply(user, [JOIN_ROLE])
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(404, "Unknown Member"))

      ApplyJoinRolesJob.new.perform("uid-1", GUILD)

      assert_nil membership_of(user)
    end

    test "a Discord outage changes nothing" do
      user = linked_user("uid-1")
      JoinRole.new(@fleet).apply(user, [JOIN_ROLE])
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(502, "Bad Gateway"))

      ApplyJoinRolesJob.new.perform("uid-1", GUILD)

      assert_predicate membership_of(user), :accepted?
    end

    test "picking a join role queues a sync that forgets who held the previous one" do
      @setting.update!(discord_join_role_id: "300000000000000002")

      assert_equal [[@fleet.id, true]], SyncFleetJoinRoleJob.jobs.pluck("args")
    end

    test "another guild clears every id from the previous one, and switching back does not restore them" do
      @setting.update!(discord_channel_id: "200000000000000001", discord_member_role_id: "300000000000000003",
        discord_announcement_channel_id: "200000000000000002", discord_officers_channel_id: "200000000000000003")
      rank = @fleet.default_member_role
      rank.update!(discord_role_id: "300000000000000004")

      @setting.update!(discord_guild_id: "100000000000000002")
      @setting.update!(discord_guild_id: GUILD)

      @setting.reload
      assert_nil @setting.discord_join_role_id
      assert_nil @setting.discord_channel_id
      assert_nil @setting.discord_member_role_id
      assert_nil @setting.discord_announcement_channel_id
      assert_nil @setting.discord_officers_channel_id
      assert_nil rank.reload.discord_role_id
    end

    test "a guild change keeps the ids saved along with it" do
      @setting.update!(discord_guild_id: "100000000000000002", discord_channel_id: "200000000000000009")

      assert_equal "200000000000000009", @setting.reload.discord_channel_id
    end

    test "a new guild and a new join role saved together keep the role" do
      @setting.update!(discord_guild_id: "100000000000000002", discord_join_role_id: "300000000000000002")

      assert_equal "300000000000000002", @setting.reload.discord_join_role_id
    end

    test "the sync admits every linked holder in the guild and ignores everyone else" do
      holder = linked_user("uid-1")
      bystander = linked_user("uid-2")
      @api.stubs(:list_guild_members).with(GUILD, after: nil).returns([
        member("uid-1", JOIN_ROLE),
        member("uid-2"),
        member("uid-unlinked", JOIN_ROLE)
      ])

      SyncFleetJoinRoleJob.new.perform(@fleet.id, true)

      assert_predicate membership_of(holder), :accepted?
      assert_nil membership_of(bystander)
    end

    test "the sync pages through the guild" do
      first = linked_user("uid-1")
      second = linked_user("uid-2")
      full_page = Array.new(ApiClient::MEMBER_PAGE_SIZE - 1) { |index| member("uid-unlinked-#{index}") } + [member("uid-1", JOIN_ROLE)]
      @api.stubs(:list_guild_members).with(GUILD, after: nil).returns(full_page)
      @api.stubs(:list_guild_members).with(GUILD, after: "uid-1").returns([member("uid-2", JOIN_ROLE)])

      SyncFleetJoinRoleJob.new.perform(@fleet.id)

      assert_predicate membership_of(first), :accepted?
      assert_predicate membership_of(second), :accepted?
    end

    test "the sync ends the role's memberships for holders no longer in the guild" do
      gone = linked_user("uid-1")
      JoinRole.new(@fleet).apply(gone, [JOIN_ROLE])
      @api.stubs(:list_guild_members).returns([])

      SyncFleetJoinRoleJob.new.perform(@fleet.id)

      assert_nil membership_of(gone)
    end

    test "the sync leaves a holder who unlinked Discord alone" do
      unlinked = linked_user("uid-1")
      JoinRole.new(@fleet).apply(unlinked, [JOIN_ROLE])
      unlinked.omniauth_connections.discord.destroy_all
      @api.stubs(:list_guild_members).returns([])

      SyncFleetJoinRoleJob.new.perform(@fleet.id)

      assert_predicate membership_of(unlinked), :accepted?
    end

    test "the sync does not tell the officers about each player it admits" do
      holder = linked_user("uid-1")
      @api.stubs(:list_guild_members).returns([member("uid-1", JOIN_ROLE)])

      SyncFleetJoinRoleJob.new.perform(@fleet.id, true)

      assert_predicate membership_of(holder), :accepted?
      refute Notification.exists?(user: @admin, notification_type: "fleet_member_accepted")
    end

    test "a sync that cannot read the guild ends nobody's membership" do
      kept = linked_user("uid-1")
      JoinRole.new(@fleet).apply(kept, [JOIN_ROLE])
      @api.stubs(:list_guild_members).raises(ApiClient::Error.new(403, "Missing Access"))

      SyncFleetJoinRoleJob.new.perform(@fleet.id)

      assert_predicate membership_of(kept), :accepted?
    end

    test "changing the join role keeps the members the previous one brought in" do
      kept = linked_user("uid-1")
      JoinRole.new(@fleet).apply(kept, [JOIN_ROLE])
      @setting.update!(discord_join_role_id: "300000000000000002")
      @api.stubs(:list_guild_members).returns([member("uid-1", JOIN_ROLE)])

      SyncFleetJoinRoleJob.new.perform(@fleet.id, true)

      assert_predicate membership_of(kept), :accepted?
    end
  end
end
