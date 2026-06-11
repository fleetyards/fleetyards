# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembersPromoteTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}/promote" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    put("Promote Member") do
      operationId "promoteFleetMember"
      description "No Member found"
      tags "FleetMembers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"
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

  test "PUT /fleets/:slug/members/:username/promote promotes the member" do
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/promote returns 404 for unknown member" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug, username: "unknown"}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/promote returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/promote returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/promote with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {}
  end
end
