# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetMembersUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/members/{id}" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet Member id", schema: {type: :string, format: :uuid}

    patch("Update Fleet Member") do
      operationId "updateFleetMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/AdminFleetMemberUpdateInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminFleetMember"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:fleets])
    @member = create(:user)
    @admin = create(:user)
    @fleet = create(:fleet, members: [@member], admins: [@admin])
    @membership = @fleet.fleet_memberships.find_by(user: @member)
    @admin_membership = @fleet.fleet_memberships.find_by(user: @admin)
    @admin_role = @fleet.fleet_roles.ranked.first
    @officer_role = @fleet.fleet_roles.ranked.second
    @member_role = @fleet.fleet_roles.ranked.last
  end

  test "PATCH /members/:id promotes a member to admin" do
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {fleet_id: @fleet.id, id: @membership.id},
      body: {fleetRoleId: @admin_role.id}

    assert_equal @admin_role, @membership.reload.fleet_role
  end

  test "PATCH /members/:id changes an officer to member" do
    @membership.update!(fleet_role: @officer_role)
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {fleet_id: @fleet.id, id: @membership.id},
      body: {fleetRoleId: @member_role.id}

    assert_equal @member_role, @membership.reload.fleet_role
  end

  test "PATCH /members/:id rejects demoting the last admin" do
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {fleet_id: @fleet.id, id: @admin_membership.id},
      body: {fleetRoleId: @member_role.id}

    assert_equal @admin_role, @admin_membership.reload.fleet_role
  end

  test "PATCH /members/:id rejects a foreign role" do
    foreign_role = create(:fleet).fleet_roles.ranked.first
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {fleet_id: @fleet.id, id: @membership.id},
      body: {fleetRoleId: foreign_role.id}

    assert_equal @member_role, @membership.reload.fleet_role
  end

  test "PATCH /members/:id returns 404 for missing membership" do
    sign_in @user

    assert_api_response :patch, 404,
      path_params: {fleet_id: @fleet.id, id: SecureRandom.uuid},
      body: {fleetRoleId: @admin_role.id}
  end

  test "PATCH /members/:id returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {fleet_id: @fleet.id, id: @membership.id},
      body: {fleetRoleId: @admin_role.id}
  end

  test "PATCH /members/:id returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :patch, 403,
      path_params: {fleet_id: @fleet.id, id: @membership.id},
      body: {fleetRoleId: @admin_role.id}
  end
end
