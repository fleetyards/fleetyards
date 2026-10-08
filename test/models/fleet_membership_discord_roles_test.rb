# frozen_string_literal: true

require "test_helper"

# When a membership change is worth a Discord round trip, and when it is not.
class FleetMembershipDiscordRolesTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    @fleet.create_fleet_notification_setting!(
      discord_guild_id: "100000000000000001",
      discord_member_role_id: "200000000000000001"
    )
    @user = create(:user)
    ::Discord::ApiClient.stubs(:configured?).returns(true)
    ::Discord::SyncMemberRolesJob.jobs.clear
  end

  def create_membership
    @fleet.fleet_memberships.create!(user: @user, fleet_role: @fleet.fleet_roles.ranked.last)
  end

  test "accepting a membership syncs the roles" do
    membership = create_membership
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.update!(aasm_state: "accepted")

    assert_equal [membership.id], ::Discord::SyncMemberRolesJob.jobs.map { |job| job["args"].first }
  end

  test "a rank an officer gives takes the membership out of the join role's hands" do
    membership = create_membership
    membership.update!(aasm_state: "accepted", discord_role_granted: true)

    membership.update!(fleet_role: @fleet.fleet_roles.ranked.first)

    refute_predicate membership.reload, :discord_role_granted?
  end

  test "a rank change syncs the roles" do
    membership = create_membership
    membership.update!(aasm_state: "accepted")
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.update!(fleet_role: @fleet.fleet_roles.ranked.first)

    assert_equal 1, ::Discord::SyncMemberRolesJob.jobs.size
  end

  test "discarding a membership syncs the roles so they come off" do
    membership = create_membership
    membership.update!(aasm_state: "accepted")
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.discard

    assert_equal 1, ::Discord::SyncMemberRolesJob.jobs.size
  end

  # A Discord round trip has no business behind an ordinary edit.
  test "an unrelated change does not sync" do
    membership = create_membership
    membership.update!(aasm_state: "accepted")
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.update!(ships_filter: "all")

    assert_equal 0, ::Discord::SyncMemberRolesJob.jobs.size
  end

  test "does not sync for a fleet with no Discord server" do
    @fleet.fleet_notification_setting.update!(discord_guild_id: nil)
    membership = create_membership
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.update!(aasm_state: "accepted")

    assert_equal 0, ::Discord::SyncMemberRolesJob.jobs.size
  end

  test "does not sync without a bot token" do
    ::Discord::ApiClient.stubs(:configured?).returns(false)
    membership = create_membership
    ::Discord::SyncMemberRolesJob.jobs.clear

    membership.update!(aasm_state: "accepted")

    assert_equal 0, ::Discord::SyncMemberRolesJob.jobs.size
  end
end
