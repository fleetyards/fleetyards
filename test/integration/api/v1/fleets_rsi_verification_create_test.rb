# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRsiVerificationCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/rsi-verification" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Generate a new RSI verification token") do
      operationId "createFleetRsiVerification"
      tags "Fleet RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "created") do
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

  test "POST /fleets/:slug/rsi-verification generates a token" do
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}

    assert_match(/\AFLEETYARDS-[A-Z0-9]{10}\z/, response.parsed_body["token"])
  end

  test "POST /fleets/:slug/rsi-verification replaces the token" do
    sign_in @admin
    @fleet.generate_rsi_verification_token!
    previous = @fleet.rsi_verification_token

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}

    assert_not_equal previous, @fleet.reload.rsi_verification_token
  end

  test "POST /fleets/:slug/rsi-verification is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "POST /fleets/:slug/rsi-verification returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
