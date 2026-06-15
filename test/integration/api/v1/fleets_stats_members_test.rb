# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsStatsMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Members Stats") do
      operationId "fleetMembersStats"
      tags "FleetStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetMemberQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMembersStats"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/stats/members returns member stats" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/members with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
