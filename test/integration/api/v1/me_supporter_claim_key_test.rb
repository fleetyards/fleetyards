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

    post("Create the supporter claim key") do
      operationId "createMySupporterClaimKey"
      tags "Me Supporter"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::SupporterClaimKey
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/me/supporter/claim-key/rotate" do
    post("Rotate the supporter claim key") do
      operationId "rotateMySupporterClaimKey"
      tags "Me Supporter"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
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

  test "GET /me/supporter/claim-key returns null before one is asked for" do
    sign_in @account

    assert_api_response :get, 200 do
      assert_nil parsed_body["key"]
    end
  end

  test "POST /me/supporter/claim-key creates a key and repeats it" do
    sign_in @account

    assert_api_response :post, 200, api_path: "/me/supporter/claim-key" do
      assert_match(/\AFY-[0-9A-Z]{4}-[0-9A-Z]{4}\z/, parsed_body["key"])
    end

    key = @account.reload.claim_key

    assert_api_response :post, 200, api_path: "/me/supporter/claim-key" do
      assert_equal key, parsed_body["key"]
    end
  end

  test "POST /me/supporter/claim-key/rotate replaces the key" do
    original = @account.ensure_claim_key!
    sign_in @account

    assert_api_response :post, 200, api_path: "/me/supporter/claim-key/rotate" do
      assert_not_equal original, parsed_body["key"]
      assert_equal @account.reload.claim_key, parsed_body["key"]
    end
  end

  test "GET /me/supporter/claim-key is unauthorized when signed out" do
    assert_api_response :get, 401
  end

  test "POST /me/supporter/claim-key/rotate is unauthorized when signed out" do
    assert_api_response :post, 401, api_path: "/me/supporter/claim-key/rotate"
  end

  test "GET /me/supporter/claim-key with an OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:read"])
  end
end
