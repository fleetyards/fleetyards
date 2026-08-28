# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMembersShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    get("Show Member") do
      operationId "fleetMember"
      description "A single membership, so a notification about it can show what state it is in now"
      tags "FleetMembers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMember
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "GET /fleets/:slug/members/:username returns the member" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, username: @member.username} do
      assert_equal @member.username, parsed_body["username"]
      assert_equal "accepted", parsed_body["status"]
    end
  end

  test "GET /fleets/:slug/members/:username reports a request that is still open" do
    requester = create(:user)
    membership = @fleet.fleet_memberships.create!(user: requester, fleet_role: @fleet.default_member_role)
    membership.request!

    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, username: requester.username} do
      assert_equal "requested", parsed_body["status"]
    end
  end

  test "GET /fleets/:slug/members/:username returns 404 for an unknown member" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, username: "unknown"}
  end

  # An outsider gets a 404 rather than a 403 - the fleet is out of their scope,
  # so there is nothing to be forbidden from. 403 is for someone who is in the
  # fleet but whose role may not read its memberships.
  test "GET /fleets/:slug/members/:username returns 403 without membership read access" do
    @fleet.default_member_role.update!(resource_access: [])

    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug, username: @admin.username}
  end

  test "GET /fleets/:slug/members/:username lets a member read their own membership" do
    @fleet.default_member_role.update!(resource_access: [])

    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "GET /fleets/:slug/members/:username returns 404 for an outsider" do
    sign_in @outsider

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "GET /fleets/:slug/members/:username returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "GET /fleets/:slug/members/:username with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
