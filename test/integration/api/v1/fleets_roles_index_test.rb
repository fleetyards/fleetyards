# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRolesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/roles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Role List") do
      operationId "fleetRoles"
      tags "FleetRoles"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetRoleExtended"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/roles returns the fleet roles" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_operator parsed_body.count, :>, 0
      assert parsed_body.first.key?("name")
      assert parsed_body.first.key?("resourceAccess")
      assert parsed_body.first.key?("permanent")
    end
  end

  test "GET /fleets/:slug/roles returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/roles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/roles with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
