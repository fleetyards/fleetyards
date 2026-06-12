# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembersAcceptRequestTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}/accept" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    put("Accept Member") do
      operationId "acceptFleetMember"
      tags "FleetMembers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(404, "No Member found") do
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
    @applicant = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @membership = create(:fleet_membership, fleet: @fleet, user: @applicant, aasm_state: :requested)
  end

  test "PUT /fleets/:slug/members/:username/accept accepts the request" do
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, username: @applicant.username}, body: {}

    notification = Notification.find_by(user: @applicant, notification_type: "fleet_request_accepted")
    assert_predicate notification, :present?
    assert_kind_of FleetMembership, notification.record
  end

  test "PUT /fleets/:slug/members/:username/accept returns 400 when the user is already a member" do
    sign_in @admin

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/accept returns 404 for unknown member" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug, username: "unknown"}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/accept returns 403 for a non-admin member" do
    sign_in @member

    assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, username: @applicant.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/accept returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, username: @applicant.username}, body: {}
  end

  test "PUT /fleets/:slug/members/:username/accept with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @applicant.username},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {}
  end
end
