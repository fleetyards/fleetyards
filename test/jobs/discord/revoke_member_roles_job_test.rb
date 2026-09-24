# frozen_string_literal: true

require "test_helper"

module Discord
  class RevokeMemberRolesJobTest < ActiveSupport::TestCase
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
      clear_jobs
    end

    def clear_jobs
      ::Discord::RevokeMemberRolesJob.jobs.clear
      ::Discord::BackfillUserMemberRolesJob.jobs.clear
    end

    def revoke_jobs
      ::Discord::RevokeMemberRolesJob.jobs.map { |job| job["args"] }
    end

    def perform(fleet_ids = [@fleet.id])
      ::Discord::RevokeMemberRolesJob.new.perform(UID, fleet_ids)
    end

    def second_fleet
      fleet = create(:fleet)
      fleet.create_fleet_notification_setting!(discord_guild_id: "guild-2", discord_member_role_id: "role-other")
      fleet.fleet_memberships.create!(user: @user, fleet_role: fleet.fleet_roles.ranked.last)
      fleet
    end

    class Triggers < RevokeMemberRolesJobTest
      test "unlinking Discord enqueues a revoke for the old uid and the member's fleets" do
        @connection.destroy!

        assert_equal [[UID, [@fleet.id]]], revoke_jobs
      end

      test "unlinking another provider enqueues nothing" do
        create(:omniauth_connection, user: @user, provider: "github", uid: "gh-1").destroy!

        assert_empty revoke_jobs
      end

      # The memberships are gone before the connection is, so the fleets have
      # to be captured by the user -- and only one revoke is enqueued.
      test "deleting the account enqueues one revoke with the fleets it was in" do
        other = second_fleet

        assert @user.destroy

        assert_equal 1, revoke_jobs.size
        uid, fleet_ids = revoke_jobs.first
        assert_equal UID, uid
        assert_equal [@fleet.id, other.id].sort, fleet_ids.sort
      end

      test "deleting the account snapshots each fleet's guild and managed roles" do
        assert @user.destroy

        _uid, _fleet_ids, snapshots = revoke_jobs.first
        assert_equal [[@fleet.id, "guild-1", [MEMBER_ROLE, RANK_ROLE].sort]], snapshots.map { |id, guild, roles| [id, guild, roles.sort] }
      end

      test "deleting an account without Discord enqueues nothing" do
        @connection.destroy!
        clear_jobs

        assert @user.destroy

        assert_empty revoke_jobs
      end
    end

    class Perform < RevokeMemberRolesJobTest
      test "removes the managed roles and leaves the rest" do
        @connection.destroy!
        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, RANK_ROLE, FOREIGN_ROLE]})
        @api.expects(:add_guild_member_role).never
        @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, RANK_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, FOREIGN_ROLE).never

        perform
      end

      test "revokes after the account is deleted" do
        other = second_fleet
        fleet_ids = [@fleet.id, other.id]
        @user.destroy!

        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, RANK_ROLE]})
        @api.stubs(:get_guild_member).with("guild-2", UID).returns({"roles" => ["role-other"]})
        @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, RANK_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-2", UID, "role-other")

        perform(fleet_ids)
      end

      # The sole admin's fleet is destroyed with the account, so only the
      # snapshot still knows its guild and roles.
      test "deleting the sole admin removes the destroyed fleet's managed roles" do
        @membership.update!(fleet_role: @fleet.fleet_roles.find_by(permanent: true))
        fleet_id = @fleet.id
        admin_role = @fleet.fleet_roles.find_by(permanent: true)
        admin_role.update!(discord_role_id: "role-admin")

        assert @user.destroy
        assert_not Fleet.exists?(fleet_id)
        args = revoke_jobs.first

        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, "role-admin", FOREIGN_ROLE]})
        @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, "role-admin")
        @api.expects(:remove_guild_member_role).with("guild-1", UID, FOREIGN_ROLE).never

        ::Discord::RevokeMemberRolesJob.new.perform(*args)
      end

      test "a destroyed fleet keeps a role another fleet in the same guild still owes" do
        @connection.destroy!
        sibling = create(:fleet)
        sibling.create_fleet_notification_setting!(discord_guild_id: "guild-1", discord_member_role_id: MEMBER_ROLE)
        other = create(:user)
        create(:omniauth_connection, user: other, provider: "discord", uid: UID)
        sibling.fleet_memberships.create!(user: other, fleet_role: sibling.fleet_roles.ranked.last).update!(aasm_state: "accepted")

        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, RANK_ROLE]})
        @api.expects(:remove_guild_member_role).with("guild-1", UID, RANK_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE).never

        ::Discord::RevokeMemberRolesJob.new.perform(UID, ["gone-fleet-id"], [["gone-fleet-id", "guild-1", [MEMBER_ROLE, RANK_ROLE]]])
      end

      test "keeps the roles another member linked to the same account is owed" do
        other = create(:user)
        create(:omniauth_connection, user: other, provider: "discord", uid: UID)
        @fleet.fleet_memberships.create!(user: other, fleet_role: @fleet.fleet_roles.ranked.first).update!(aasm_state: "accepted")
        @connection.destroy!

        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE, RANK_ROLE]})
        @api.expects(:remove_guild_member_role).with("guild-1", UID, RANK_ROLE)
        @api.expects(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE).never

        perform
      end

      test "skips a fleet with no Discord server" do
        @fleet.fleet_notification_setting.update!(discord_guild_id: nil)
        @connection.destroy!
        @api.expects(:get_guild_member).never

        perform
      end

      test "removes nothing once the same account is linked again" do
        @connection.destroy!
        create(:omniauth_connection, user: @user, provider: "discord", uid: UID)
        @api.stubs(:get_guild_member).returns({"roles" => [MEMBER_ROLE, RANK_ROLE]})
        @api.expects(:remove_guild_member_role).never

        perform
      end

      test "one fleet's permanent error does not stop the others" do
        second_fleet
        @connection.destroy!

        @api.stubs(:get_guild_member).with("guild-1", UID).returns({"roles" => [MEMBER_ROLE]})
        @api.stubs(:get_guild_member).with("guild-2", UID).returns({"roles" => ["role-other"]})
        @api.stubs(:remove_guild_member_role).with("guild-1", UID, MEMBER_ROLE).raises(::Discord::ApiClient::Error.new(400, "Bad Request"))
        @api.expects(:remove_guild_member_role).with("guild-2", UID, "role-other")

        assert_nothing_raised { perform(@user.fleet_memberships.pluck(:fleet_id)) }
      end

      test "a rate limit is left for the job to retry" do
        @connection.destroy!
        @api.stubs(:get_guild_member).raises(::Discord::ApiClient::Error.new(429, "Too Many Requests"))

        assert_raises(::Discord::ApiClient::Error) { perform }
      end

      test "hands back to the backfill when the account was relinked mid-run" do
        @connection.destroy!
        @api.stubs(:get_guild_member).returns({"roles" => [MEMBER_ROLE]})
        @api.stubs(:remove_guild_member_role).with do
          # Skips the create hook, so only the job can enqueue the backfill.
          OmniauthConnection.insert!({user_id: @user.id, provider: "discord", uid: UID})
          true
        end
        clear_jobs

        perform

        assert_equal [@user.id], ::Discord::BackfillUserMemberRolesJob.jobs.map { |job| job["args"].first }
      end

      test "does nothing without a bot token" do
        ::Discord::ApiClient.stubs(:configured?).returns(false)
        @connection.destroy!
        @api.expects(:get_guild_member).never

        perform
      end
    end
  end
end
