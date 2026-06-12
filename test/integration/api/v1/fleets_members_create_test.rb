# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembersCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Member") do
      operationId "createFleetMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetMemberCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
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
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @new_member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "POST /fleets/:slug/members invites the new user" do
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {username: @new_member.username} do
      assert_equal @new_member.username, parsed_body["username"]
      assert_equal "invited", parsed_body["status"]
    end

    notification = Notification.find_by(user: @new_member, notification_type: "fleet_invite")
    assert_predicate notification, :present?
    assert_kind_of FleetMembership, notification.record
  end

  test "POST /fleets/:slug/members returns 400 for unknown username" do
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {username: "unknown"}
  end

  test "POST /fleets/:slug/members returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {fleetSlug: "unknown-fleet"}, body: {username: @new_member.username}
  end

  test "POST /fleets/:slug/members returns 403 for non-admin" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {username: @new_member.username}
  end

  test "POST /fleets/:slug/members returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}, body: {username: @new_member.username}
  end

  test "POST /fleets/:slug/members with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {username: @new_member.username}
  end
end
