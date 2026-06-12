# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInviteUrlsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/invite-urls" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Invite Urls List") do
      operationId "fleetInviteUrls"
      tags "fleetInviteUrls"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetInviteUrl"}
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
    create_list(:fleet_invite_url, 4, fleet: @fleet, user: @admin)
  end

  test "GET /fleets/:slug/invite-urls lists invite urls" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 4, parsed_body.count
    end
  end

  test "GET /fleets/:slug/invite-urls honours perPage" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {perPage: 1} do
      assert_equal 1, parsed_body.count
    end
  end

  test "GET /fleets/:slug/invite-urls returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/invite-urls returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/invite-urls returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/invite-urls with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
