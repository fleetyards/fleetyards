# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFidClaimDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/fid-claim" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    delete("Withdraw the fleet's FID claim") do
      operationId "destroyFleetFidClaim"
      tags "Fleet FID Claims"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetFidClaimStatus
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
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
    @claimant = create(:fleet, :rsi_verified, fid: "TEST-1", rsi_sid: "TEST", created_by: @admin.id, members: [@member])
    @holder = create(:fleet, fid: "test", created_by: create(:user).id)
  end

  test "DELETE /fleets/:slug/fid-claim withdraws the open claim" do
    claim = FleetFidClaim.open_for!(@claimant, user: @admin)
    sign_in @admin

    assert_api_response :delete, 200, path_params: {fleetSlug: @claimant.slug}

    assert claim.reload.cancelled_by_withdrawn?
    assert_equal "claimable", response.parsed_body["availability"]
  end

  test "DELETE /fleets/:slug/fid-claim without an open claim is refused" do
    sign_in @admin

    assert_api_response :delete, 400, path_params: {fleetSlug: @claimant.slug}
  end

  test "DELETE /fleets/:slug/fid-claim with OAuth bearer token" do
    FleetFidClaim.open_for!(@claimant, user: @admin)

    assert_api_response :delete, 200,
      path_params: {fleetSlug: @claimant.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/fid-claim is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {fleetSlug: @claimant.slug}
  end

  test "DELETE /fleets/:slug/fid-claim returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @claimant.slug}
  end
end
