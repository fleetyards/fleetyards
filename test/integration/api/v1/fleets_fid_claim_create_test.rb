# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFidClaimCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/fid-claim" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Claim the FID equal to the fleet's verified RSI SID") do
      operationId "createFleetFidClaim"
      tags "Fleet FID Claims"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "created") do
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
    @holder_admin = create(:user)
    @member = create(:user)
    @claimant = create(:fleet, :rsi_verified, fid: "TEST-1", rsi_sid: "TEST", created_by: @admin.id, members: [@member])
    @holder = create(:fleet, fid: "test", created_by: @holder_admin.id)
  end

  test "POST /fleets/:slug/fid-claim opens a claim on the verified SID" do
    sign_in @admin

    assert_difference -> { FleetFidClaim.open.count }, 1 do
      assert_api_response :post, 201, path_params: {fleetSlug: @claimant.slug}
    end

    assert_equal "pending", response.parsed_body["availability"]
    assert_equal "TEST", response.parsed_body.dig("outgoing", "fid")
    assert Notification.exists?(user: @holder_admin, notification_type: :fleet_fid_claim_opened)
  end

  test "POST /fleets/:slug/fid-claim refuses a fleet that is not verified" do
    @claimant.revoke_rsi_verification!
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @claimant.slug}

    assert_equal "validation_error.fleet_fid_claim.create", response.parsed_body["code"]
  end

  test "POST /fleets/:slug/fid-claim refuses an FID nobody holds" do
    @holder.update!(fid: "elsewhere")
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @claimant.slug}
  end

  test "POST /fleets/:slug/fid-claim with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @claimant.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "POST /fleets/:slug/fid-claim is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @claimant.slug}
  end

  test "POST /fleets/:slug/fid-claim returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @claimant.slug}
  end
end
