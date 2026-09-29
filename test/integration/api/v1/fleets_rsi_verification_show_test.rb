# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRsiVerificationShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/rsi-verification" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Show the fleet's RSI verification") do
      operationId "fleetRsiVerification"
      tags "Fleet RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetRsiVerification
      end

      response(401, "unauthorized") do
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
    @fleet = create(:fleet, created_by: @admin.id, members: [@member], rsi_sid: "TEST")
  end

  test "GET /fleets/:slug/rsi-verification returns the verification" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}

    assert_equal "TEST", response.parsed_body["sid"]
    assert_equal false, response.parsed_body["verified"]
    assert_equal %w[checkedAt sid status token verified verifiedAt], response.parsed_body.keys.sort
  end

  test "GET /fleets/:slug/rsi-verification with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/rsi-verification is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/rsi-verification returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
