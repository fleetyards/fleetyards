# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeHangarShareRotateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/hangar/share/rotate" do
    post("Rotate hangar share link") do
      operationId "rotateMyHangarShare"
      tags "Me Hangar Share"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
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

  test "POST /me/hangar/share/rotate replaces the token" do
    old_token = @account.ensure_hangar_share_token!
    sign_in @account

    assert_api_response :post, 200 do
      refute_includes parsed_body["shareUrl"], old_token
    end

    new_token = @account.reload.hangar_share_token
    assert new_token.present?
    refute_equal old_token, new_token
  end

  test "POST /me/hangar/share/rotate does not bring back a deleted link" do
    sign_in @account

    assert_api_response :post, 200 do
      assert_equal false, parsed_body["enabled"]
      assert_nil parsed_body["shareUrl"]
    end

    assert_nil @account.reload.hangar_share_token
  end

  test "POST /me/hangar/share/rotate with OAuth bearer token" do
    @account.ensure_hangar_share_token!

    assert_api_response :post, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "POST /me/hangar/share/rotate returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "POST /me/hangar/share/rotate returns 401 when not signed in" do
    assert_api_response :post, 401
  end
end
