# frozen_string_literal: true

require "test_helper"

class Api::V1::FleetsNotificationsUpdateBehaviourTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    sign_in @admin
  end

  test "names the field when a server's name is saved as its id" do
    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordGuildId: "Stanton Haulers [SHL]"}, as: :json

    assert_response :bad_request
    error = JSON.parse(response.body)["errors"].sole
    assert_equal "discordGuildId", error["attribute"]
    assert_match "numeric ID", error["messages"].sole["message"]
    assert_nil @fleet.reload.fleet_notification_setting&.discord_guild_id
  end

  test "sets and clears the Discord join role" do
    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordJoinRoleId: "345678901234567890"}, as: :json

    assert_response :ok
    assert_equal "345678901234567890", JSON.parse(response.body)["discordJoinRoleId"]

    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordJoinRoleId: nil}, as: :json

    assert_response :ok
    assert_nil @fleet.reload.fleet_notification_setting.discord_join_role_id
  end

  test "leaves the join role to members who may hand out invites" do
    @fleet.create_fleet_notification_setting!(discord_join_role_id: "345678901234567890")
    notifier = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Herald", resource_access: ["fleet:notifications:manage"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: notifier, fleet_role: role)
    sign_in notifier

    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordJoinRoleId: nil}, as: :json

    assert_response :forbidden
    assert_equal "345678901234567890", @fleet.reload.fleet_notification_setting.discord_join_role_id
  end

  test "lets a member without the invite privilege resend the join role unchanged" do
    @fleet.create_fleet_notification_setting!(discord_join_role_id: "345678901234567890")
    notifier = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Herald", resource_access: ["fleet:notifications:manage"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: notifier, fleet_role: role)
    sign_in notifier

    patch "/api/v1/fleets/#{@fleet.slug}/notifications",
      params: {discordJoinRoleId: "345678901234567890", discordChannelId: "234567890123456789"}, as: :json

    assert_response :ok
    assert_equal "234567890123456789", @fleet.reload.fleet_notification_setting.discord_channel_id
  end

  test "lets an officer with the invite privilege set the join role" do
    officer = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter",
      resource_access: ["fleet:notifications:manage", "fleet:invites:create"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: officer, fleet_role: role)
    sign_in officer

    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordJoinRoleId: "345678901234567890"}, as: :json

    assert_response :ok
    assert_equal "345678901234567890", @fleet.reload.fleet_notification_setting.discord_join_role_id
  end

  test "leaves a server change that would clear the join role to members who may hand out invites" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "123456789012345678", discord_join_role_id: "345678901234567890")
    notifier = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Herald", resource_access: ["fleet:notifications:manage"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: notifier, fleet_role: role)
    sign_in notifier

    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordGuildId: "223456789012345678"}, as: :json

    assert_response :forbidden
    assert_equal "345678901234567890", @fleet.reload.fleet_notification_setting.discord_join_role_id
  end

  test "lets a member without the invite privilege change a server that has no join role" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "123456789012345678")
    notifier = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Herald", resource_access: ["fleet:notifications:manage"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: notifier, fleet_role: role)
    sign_in notifier

    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordGuildId: "223456789012345678"}, as: :json

    assert_response :ok
    assert_equal "223456789012345678", @fleet.reload.fleet_notification_setting.discord_guild_id
  end
end
