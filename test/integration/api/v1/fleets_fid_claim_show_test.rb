# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFidClaimShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/fid-claim" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Show the fleet's FID claims") do
      operationId "fleetFidClaim"
      tags "Fleet FID Claims"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetFidClaimStatus
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
    @claimant_admin = create(:user)
    @holder_admin = create(:user)
    @member = create(:user)
    @claimant = create(:fleet, :rsi_verified, fid: "TEST-1", rsi_sid: "TEST", created_by: @claimant_admin.id)
    @holder = create(:fleet, fid: "test", created_by: @holder_admin.id, members: [@member])
  end

  test "GET /fleets/:slug/fid-claim says a verified fleet can claim its SID" do
    sign_in @claimant_admin

    assert_api_response :get, 200, path_params: {fleetSlug: @claimant.slug}

    assert_equal "claimable", response.parsed_body["availability"]
    assert_equal "TEST", response.parsed_body["fid"]
    assert_nil response.parsed_body["outgoing"]
  end

  test "GET /fleets/:slug/fid-claim shows both sides of an open claim" do
    FleetFidClaim.open_for!(@claimant, user: @claimant_admin)

    sign_in @claimant_admin
    assert_api_response :get, 200, path_params: {fleetSlug: @claimant.slug}
    assert_equal "pending", response.parsed_body["availability"]
    assert_equal "test", response.parsed_body.dig("outgoing", "holderFid")

    sign_in @holder_admin
    assert_api_response :get, 200, path_params: {fleetSlug: @holder.slug}
    assert_equal "unverified", response.parsed_body["availability"]
    assert_equal @claimant.name, response.parsed_body.dig("incoming", "claimantName")
  end

  test "GET /fleets/:slug/fid-claim with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @claimant.slug},
      headers: oauth_headers_for(@claimant_admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/fid-claim is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @holder.slug}
  end

  test "GET /fleets/:slug/fid-claim returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @claimant.slug}
  end
end
