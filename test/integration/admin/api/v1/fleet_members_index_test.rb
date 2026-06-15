# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetMembersIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/members" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    get("Fleet Members list") do
      operationId "fleetMembers"
      tags "FleetMembers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/AdminFleetMemberQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminFleetMembers"
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
  end

  test "GET /fleets/:fleet_id/members lists members" do
    fleet = create(:fleet, members: create_list(:user, 3))
    sign_in @user

    assert_api_response :get, 200, path_params: {fleet_id: fleet.id}
  end

  test "GET /fleets/:fleet_id/members returns 404 for missing fleet" do
    sign_in @user

    assert_api_response :get, 404, path_params: {fleet_id: SecureRandom.uuid}
  end

  test "GET /fleets/:fleet_id/members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleet_id: SecureRandom.uuid}
  end

  test "GET /fleets/:fleet_id/members returns 403 for admin without access" do
    fleet = create(:fleet, members: create_list(:user, 3))
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {fleet_id: fleet.id}
  end
end
