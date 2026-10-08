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
      @fleet.fleet_notification_setting.update_columns(discord_join_role_swept_at: Time.current)
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

    def ask_to_join(user = @user)
      @fleet.fleet_memberships.create!(user:, fleet_role: @fleet.default_member_role).tap do |asking|
        join_role.request_or_join(asking)
      end
    end

    test "a player asking to join while holding the role is admitted" do
      @api.stubs(:get_guild_member).with(GUILD, "discord-uid-1").returns({"roles" => [OTHER_ROLE, JOIN_ROLE]})

      asking = ask_to_join

      assert_predicate asking.reload, :accepted?
      assert_predicate asking, :discord_role_granted?
      assert FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "a player holding the role whose join does not save gets a request" do
      @api.stubs(:get_guild_member).returns({"roles" => [JOIN_ROLE]})
      FleetMembership.any_instance.stubs(:join!).returns(false)

      asking = ask_to_join

      assert_predicate asking.reload, :requested?
      refute_predicate asking, :discord_role_granted?
      refute FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "a player Discord cannot find gets a request" do
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(404, "Unknown Member"))

      assert_predicate ask_to_join.reload, :requested?
    end

    test "a player Discord does not answer for in time gets a request" do
      @api.stubs(:get_guild_member).raises(Faraday::TimeoutError)

      assert_predicate ask_to_join.reload, :requested?
    end

    test "a player without a linked Discord account gets a request" do
      @api.expects(:get_guild_member).never

      assert_predicate ask_to_join(create(:user)).reload, :requested?
    end

    test "a player whose role update holds the lock too long gets a request" do
      JoinRole.stubs(:with_member_lock).returns(false)

      assert_predicate ask_to_join.reload, :requested?
    end

    test "asking to join stands aside once an update has admitted the player" do
      @api.expects(:get_guild_member).never
      asking = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      asking.update!(aasm_state: "accepted")

      assert join_role.request_or_join(asking)
      assert_predicate asking, :accepted?
    end

    test "gaining the role makes the player a member with the default role" do
      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate membership, :accepted?
      assert_predicate membership, :discord_role_granted?
      assert_equal @fleet.default_member_role, membership.fleet_role
      assert Notification.exists?(user: @user, notification_type: "fleet_joined_by_discord_role")
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

    test "gaining the role finishes an abandoned request to join" do
      abandoned = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)

      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate abandoned.reload, :accepted?
      assert_predicate abandoned, :discord_role_granted?
      assert FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "a join that fails leaves no membership behind and is tried again on the next update" do
      FleetMembership.any_instance.stubs(:join!).returns(false)

      join_role.apply(@user, [JOIN_ROLE])

      assert_nil @fleet.fleet_memberships.with_discarded.find_by(user: @user)
      refute FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "an admission that raises leaves the role unrecorded, so the next update tries again" do
      invitation = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      invitation.invite!
      FleetMembership.any_instance.stubs(:accept_invitation!).raises(ActiveRecord::RecordInvalid)

      assert_raises(ActiveRecord::RecordInvalid) { join_role.apply(@user, [JOIN_ROLE]) }

      refute FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
    end

    test "asking to join that gave up waiting leaves a membership the role admitted alone" do
      JoinRole.stubs(:with_member_lock).returns(false)
      asking = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      join_role.apply(@user, [JOIN_ROLE])

      assert join_role.request_or_join(asking)
      assert_predicate asking.reload, :accepted?
    end

    test "gaining the role does not overrule an officer who declined the player" do
      declined = @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role)
      declined.update!(aasm_state: "declined")

      join_role.apply(@user, [JOIN_ROLE])

      assert_predicate declined.reload, :declined?
    end

    test "a declined player holding the role is recorded, so their next update queues nothing" do
      @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.default_member_role).update!(aasm_state: "declined")
      join_role.apply(@user, [JOIN_ROLE])
      ApplyJoinRolesJob.jobs.clear

      JoinRole.member_changed(GUILD, "discord-uid-1", [JOIN_ROLE, OTHER_ROLE])

      assert_empty ApplyJoinRolesJob.jobs
    end

    test "a quiet admission tells the player and the members' views but not the officers" do
      FleetVehiclesChannel.expects(:broadcast_to).with(@admin, anything).at_least_once
      FleetVehiclesChannel.stubs(:broadcast_to).with(@user, anything)

      join_role.apply(@user, [JOIN_ROLE], quiet: true)

      assert_predicate membership, :accepted?
      assert Notification.exists?(user: @user, notification_type: "fleet_joined_by_discord_role")
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

    test "a role not yet swept does not bring back a member who left" do
      join_role.apply(@user, [JOIN_ROLE])
      membership.discard
      join_role.apply(@user, [])
      @fleet.fleet_notification_setting.update_columns(discord_join_role_swept_at: nil)

      join_role.apply(@user, [JOIN_ROLE])

      assert_nil membership
      assert FleetDiscordRoleHolder.exists?(fleet: @fleet, user: @user)
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

      JoinRole.member_changed("100000000000000099", "discord-uid-1", [JOIN_ROLE])
      JoinRole.member_changed(GUILD, "discord-uid-unlinked", [JOIN_ROLE])
      assert_empty ApplyJoinRolesJob.jobs

      JoinRole.member_changed(GUILD, "discord-uid-1", [JOIN_ROLE])
      assert_equal [["discord-uid-1", GUILD]], ApplyJoinRolesJob.jobs.pluck("args")
    end

    test "a member update that leaves the join role as recorded queues nothing" do
      join_role.apply(@user, [JOIN_ROLE])
      ApplyJoinRolesJob.jobs.clear

      JoinRole.member_changed(GUILD, "discord-uid-1", [JOIN_ROLE, OTHER_ROLE])
      assert_empty ApplyJoinRolesJob.jobs

      JoinRole.member_changed(GUILD, "discord-uid-1", [OTHER_ROLE])
      assert_equal 1, ApplyJoinRolesJob.jobs.size
    end
  end
end
