# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeSupporterClaimKeyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/supporter/claim-key" do
    get("Show the supporter claim key") do
      operationId "mySupporterClaimKey"
      tags "Me Supporter"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::SupporterClaimKey
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @account = create(:user)
  end

  test "GET /me/supporter/claim-key generates one on first read" do
    assert_nil @account.claim_key
    sign_in @account

    assert_api_response :get, 200 do
      assert_match(/\AFY-[0-9A-Z]{4}-[0-9A-Z]{4}\z/, parsed_body["key"])
    end

    assert_not_nil @account.reload.claim_key
  end

  # The key goes into recurring payments, so reading it again must never hand
  # back a different one.
  test "GET /me/supporter/claim-key is stable across reads" do
    sign_in @account

    first = nil
    assert_api_response :get, 200 do
      first = parsed_body["key"]
    end

    assert_api_response :get, 200 do
      assert_equal first, parsed_body["key"]
    end

    assert_equal @account.reload.claim_key, first
  end

  test "GET /me/supporter/claim-key is unauthorized when signed out" do
    assert_api_response :get, 401
  end

  test "GET /me/supporter/claim-key with an OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:read"])
  end
end
