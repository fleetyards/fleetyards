# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsDiscordRoleMappingsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/discord-role-mappings" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Discord Role Mappings") do
      operationId "fleetDiscordRoleMappings"
      tags "FleetNotificationSettings"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Discord::FleetDiscordRoleMappings
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - needs fleet:notifications:manage") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Fleet Discord Role Mappings") do
      operationId "updateFleetDiscordRoleMappings"
      tags "FleetNotificationSettings"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetDiscordRoleMappingsUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Discord::FleetDiscordRoleMappings
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - needs fleet:notifications:manage") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @member_role = @fleet.fleet_roles.find_by!(slug: "member")
    @officer_role = @fleet.fleet_roles.find_by!(slug: "officer")
    @admin_role = @fleet.fleet_roles.find_by!(slug: "admin")
    ::Discord::BackfillFleetMemberRolesJob.jobs.clear
  end

  def path_params
    {fleetSlug: @fleet.slug}
  end

  def member_with(*privileges)
    user = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Rank #{privileges.join(" ")}", resource_access: privileges)
    create(:fleet_membership, :accepted, fleet: @fleet, user:, fleet_role: role)
    user
  end

  def mapping(role, discord_role_id)
    {fleetRoleId: role.id, discordRoleId: discord_role_id}
  end

  test "GET lists every rank with its Discord role, highest first" do
    @officer_role.update!(discord_role_id: "300000000000000001")
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@admin_role.id, @officer_role.id, @member_role.id], parsed_body["items"].pluck("fleetRoleId")
      assert_equal [nil, "300000000000000001", nil], parsed_body["items"].pluck("discordRoleId")
      assert_equal @officer_role.name, parsed_body["items"].second["name"]
    end
  end

  test "GET is open to whoever manages the fleet's Discord settings" do
    sign_in member_with("fleet:notifications:manage")

    assert_api_response :get, 200, path_params: path_params
  end

  test "GET is forbidden for a member who may only manage ranks" do
    sign_in member_with("fleet:roles:manage")

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET is forbidden for a plain member" do
    sign_in @member

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end

  test "PUT maps, replaces and clears ranks, leaving the ones it does not name" do
    @officer_role.update!(discord_role_id: "300000000000000001")
    @admin_role.update!(discord_role_id: "300000000000000009")
    ::Discord::BackfillFleetMemberRolesJob.jobs.clear
    sign_in @admin

    body = {mappings: [mapping(@member_role, "300000000000000002"), mapping(@officer_role, nil)]}

    assert_api_response :put, 200, path_params: path_params, body: do
      assert_equal [@admin_role, @officer_role, @member_role].map(&:id), parsed_body["items"].pluck("fleetRoleId")
    end

    assert_equal "300000000000000002", @member_role.reload.discord_role_id
    assert_nil @officer_role.reload.discord_role_id
    assert_equal "300000000000000009", @admin_role.reload.discord_role_id
  end

  test "PUT re-syncs the ranks it changed, retiring the role a rank lost" do
    @officer_role.update!(discord_role_id: "300000000000000001")
    ::Discord::BackfillFleetMemberRolesJob.jobs.clear
    sign_in @admin

    body = {mappings: [mapping(@officer_role, nil), mapping(@member_role, nil)]}

    assert_api_response(:put, 200, path_params: path_params, body:)

    assert_equal [[@fleet.id, @officer_role.id, ["300000000000000001"]]],
      ::Discord::BackfillFleetMemberRolesJob.jobs.map { |job| job["args"] }
  end

  test "PUT lets a Discord settings manager map the Admin rank too" do
    sign_in member_with("fleet:notifications:manage")

    assert_api_response :put, 200, path_params: path_params, body: {mappings: [mapping(@admin_role, "300000000000000003")]}

    assert_equal "300000000000000003", @admin_role.reload.discord_role_id
  end

  test "PUT refuses a role name in place of an id and changes nothing" do
    sign_in @admin

    body = {mappings: [mapping(@member_role, "300000000000000002"), mapping(@officer_role, "Officers")]}

    assert_api_response :put, 400, path_params: path_params, body: do
      assert_equal "validation_error.fleet_discord_role_mappings.update", parsed_body["code"]
    end

    assert_nil @member_role.reload.discord_role_id
    assert_nil @officer_role.reload.discord_role_id
  end

  test "PUT returns 404 for another fleet's rank" do
    other = create(:fleet).fleet_roles.find_by!(slug: "member")
    sign_in @admin

    assert_api_response :put, 404, path_params: path_params, body: {mappings: [mapping(other, "300000000000000002")]}

    assert_nil other.reload.discord_role_id
  end

  test "PUT is forbidden for a plain member" do
    sign_in @member

    assert_api_response :put, 403, path_params: path_params, body: {mappings: [mapping(@member_role, "300000000000000002")]}

    assert_nil @member_role.reload.discord_role_id
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params, body: {mappings: []}
  end
end
