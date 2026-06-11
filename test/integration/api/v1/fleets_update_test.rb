# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    put("Update Fleet") do
      operationId "updateFleet"
      description "You are not an Admin or Officer of this Fleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "PUT /fleets/:slug updates the fleet" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {discord: "https://discord.gg/1234567890"} do
      assert_equal "discord.gg/1234567890", parsed_body["discord"]
    end
  end

  test "PUT /fleets/:slug returns 404 for unknown slug" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {slug: "unknown-fleet"}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug returns 403 for a member" do
    sign_in @member

    assert_api_response :put, 403, path_params: {slug: @fleet.slug}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {slug: @fleet.slug}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {discord: "https://discord.gg/1234567890"}
  end
end
