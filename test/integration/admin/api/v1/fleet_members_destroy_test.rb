# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetMembersDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/members/{id}" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet Member id", schema: {type: :string, format: :uuid}

    delete("Remove Fleet Member") do
      operationId "removeFleetMember"
      tags "FleetMembers"
      produces "application/json"

      response(204, "successful")

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
  end

  test "DELETE /members/:id discards the membership" do
    sign_in @user

    assert_api_response :delete, 204, path_params: {fleet_id: @fleet.id, id: @membership.id}

    assert @membership.reload.discarded?
    assert_not @fleet.fleet_memberships.kept.exists?(@membership.id)
  end

  test "DELETE /members/:id rejects removing an admin-role member" do
    sign_in @user

    assert_api_response :delete, 400, path_params: {fleet_id: @fleet.id, id: @admin_membership.id}

    assert_not @admin_membership.reload.discarded?
  end

  test "DELETE /members/:id returns 404 for missing membership" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {fleet_id: @fleet.id, id: SecureRandom.uuid}
  end

  test "DELETE /members/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleet_id: @fleet.id, id: @membership.id}
  end

  test "DELETE /members/:id returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {fleet_id: @fleet.id, id: @membership.id}
  end
end
