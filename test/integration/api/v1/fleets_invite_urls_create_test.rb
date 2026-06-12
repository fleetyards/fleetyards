# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInviteUrlsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/invite-urls" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Fleet Invite Url") do
      operationId "createFleetInviteUrl"
      tags "FleetInviteUrls"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInviteUrlCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInviteUrl"
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
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "POST /fleets/:slug/invite-urls creates an invite url" do
    sign_in @admin
    travel_to Time.utc(2305, 6, 13, 12, 0, 0)

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {expiresAfterMinutes: 60} do
      assert_equal "2305-06-13T13:00:00Z", parsed_body["expiresAfter"]
    end
  end

  test "POST /fleets/:slug/invite-urls returns 400 for invalid input" do
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {limit: -100}
  end

  test "POST /fleets/:slug/invite-urls returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {fleetSlug: "unknown-fleet"}, body: {expiresAfterMinutes: 60}
  end

  test "POST /fleets/:slug/invite-urls returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {expiresAfterMinutes: 60}
  end

  test "POST /fleets/:slug/invite-urls returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}, body: {expiresAfterMinutes: 60}
  end

  test "POST /fleets/:slug/invite-urls with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {expiresAfterMinutes: 60}
  end
end
