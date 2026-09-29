# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRsiVerificationCheckTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/rsi-verification/check" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Check the RSI org page for the verification token") do
      operationId "checkFleetRsiVerification"
      tags "Fleet RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetRsiVerification
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
    @fleet = create(:fleet, created_by: @admin.id, members: [@member], rsi_sid: "TEST")
    @fleet.generate_rsi_verification_token!
    FleetRsiVerificationJob.clear
  end

  test "POST /fleets/:slug/rsi-verification/check queues a check" do
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug}

    assert_equal "pending", response.parsed_body["status"]
    assert response.parsed_body["nextCheckAt"].present?
    assert_equal 1, FleetRsiVerificationJob.jobs.size
    assert_equal [@fleet.id, FleetRsiVerification.generation_of(@fleet.reload.rsi_verification_checked_at)],
      FleetRsiVerificationJob.jobs.first["args"]
  end

  test "POST /fleets/:slug/rsi-verification/check inside the cooldown does not reach RSI again" do
    sign_in @admin
    @fleet.update!(rsi_verification_checked_at: Time.current, rsi_verification_status: :token_missing)

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug}

    assert_equal "token_missing", response.parsed_body["status"]
    assert_empty FleetRsiVerificationJob.jobs
  end

  test "POST /fleets/:slug/rsi-verification/check names the end of the cooldown to the microsecond" do
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug}

    expected = (@fleet.reload.rsi_verification_checked_at + Fleet::RSI_VERIFICATION_COOLDOWN).utc.iso8601(6)
    assert_equal expected, response.parsed_body["nextCheckAt"]
  end

  test "POST /fleets/:slug/rsi-verification/check needs a SID" do
    sign_in @admin
    @fleet.update!(rsi_sid: nil)

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}

    assert_equal "validation_error.fleet_rsi_verification.check", response.parsed_body["code"]
  end

  test "POST /fleets/:slug/rsi-verification/check is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "POST /fleets/:slug/rsi-verification/check returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
