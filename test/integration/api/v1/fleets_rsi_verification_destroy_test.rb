# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRsiVerificationDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/rsi-verification" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    delete("Remove the fleet's RSI organisation verification") do
      operationId "destroyFleetRsiVerification"
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
    @fleet = create(:fleet, :rsi_verified, created_by: @admin.id, members: [@member], rsi_sid: "TEST")
  end

  test "DELETE /fleets/:slug/rsi-verification unverifies the fleet and keeps its SID" do
    sign_in @admin

    assert_api_response :delete, 200, path_params: {fleetSlug: @fleet.slug}

    @fleet.reload
    assert_not @fleet.rsi_verified?
    assert_equal "TEST", @fleet.rsi_sid
  end

  test "DELETE /fleets/:slug/rsi-verification is not for a member who cannot manage the fleet" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug}

    assert @fleet.reload.rsi_verified?
  end

  test "DELETE /fleets/:slug/rsi-verification returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
