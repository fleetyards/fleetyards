# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FleetMembersLoginAsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/members/{id}/login-as" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet Member id", schema: {type: :string, format: :uuid}

    get("Login as Fleet Member") do
      operationId "loginAsFleetMember"
      tags "FleetMembers"
      produces "application/json"

      response(204, "successful")

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
    @fleet = create(:fleet, members: [@member])
    @membership = @fleet.fleet_memberships.first
  end

  test "GET /login-as logs in as the fleet member" do
    sign_in @user

    assert_api_response :get, 204, path_params: {fleet_id: @fleet.id, id: @membership.id}
  end

  test "GET /login-as returns 404 for missing membership" do
    sign_in @user

    assert_api_response :get, 404, path_params: {fleet_id: @fleet.id, id: SecureRandom.uuid}
  end

  test "GET /login-as returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleet_id: @fleet.id, id: @membership.id}
  end

  test "GET /login-as returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {fleet_id: @fleet.id, id: @membership.id}
  end
end
