# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeHangarShareShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/hangar/share" do
    get("Show hangar share link") do
      operationId "myHangarShare"
      tags "Me Hangar Share"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarShare
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @account = create(:user, :private_hangar)
  end

  test "GET /me/hangar/share returns disabled when no token is set" do
    sign_in @account

    assert_api_response :get, 200 do
      assert_equal false, parsed_body["enabled"]
      assert_nil parsed_body["shareUrl"]
    end
  end

  test "GET /me/hangar/share returns the share url when a token is set" do
    token = @account.ensure_hangar_share_token!
    sign_in @account

    assert_api_response :get, 200 do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["shareUrl"], "/h/#{@account.username}"
      assert_includes parsed_body["shareUrl"], "share=#{token}"
    end
  end

  test "GET /me/hangar/share with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:read"])
  end

  test "GET /me/hangar/share returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "GET /me/hangar/share returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
