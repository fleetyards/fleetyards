# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCheckTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/check" do
    post("Check Fleet FID Availability") do
      operationId "checkFID"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::CheckInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::FleetFidCheck
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /fleets/check reports the FID as taken" do
    create(:fleet, fid: "STF")
    sign_in @user

    assert_api_response :post, 200, body: {value: "STF"} do
      assert_equal true, parsed_body["taken"]
    end
  end

  test "POST /fleets/check suggests a free FID when a taken one could be an RSI SID" do
    create(:fleet, fid: "STF")
    create(:fleet, fid: "STF-1")
    sign_in @user

    assert_api_response :post, 200, body: {value: "stf"} do
      assert_equal true, parsed_body["taken"]
      assert_equal "STF-2", parsed_body["suggestion"]
    end
  end

  test "POST /fleets/check suggests nothing for an FID no SID looks like" do
    create(:fleet, fid: "my_fleet")
    sign_in @user

    assert_api_response :post, 200, body: {value: "my_fleet"} do
      assert_equal true, parsed_body["taken"]
      assert_nil parsed_body["suggestion"]
    end
  end

  test "POST /fleets/check reports an FID with an open claim as taken" do
    claimant = create(:fleet, :rsi_verified, fid: "STF-1", rsi_sid: "STF")
    holder = create(:fleet, fid: "STF", created_by: create(:user).id)
    FleetFidClaim.open_for!(claimant, user: nil)
    holder.update!(fid: "elsewhere")
    sign_in @user

    assert_api_response :post, 200, body: {value: "STF"} do
      assert_equal true, parsed_body["taken"]
    end
  end

  test "POST /fleets/check returns 401 when not signed in" do
    assert_api_response :post, 401, body: {value: "STF"}
  end

  test "POST /fleets/check with OAuth bearer token" do
    create(:fleet, fid: "STF")

    assert_api_response :post, 200,
      headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:read"]),
      body: {value: "STF"}
  end

  test "POST /fleets/check returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@user, scopes: ["public"]),
      body: {value: "STF"}
  end
end
