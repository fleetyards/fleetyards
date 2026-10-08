# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeHangarShareCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/hangar/share" do
    post("Create hangar share link") do
      operationId "createMyHangarShare"
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

    delete("Delete hangar share link") do
      operationId "destroyMyHangarShare"
      tags "Me Hangar Share"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(204, "successful") do
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @account = create(:user, :private_hangar)
  end

  test "POST /me/hangar/share creates a share link" do
    sign_in @account

    assert_api_response :post, 200 do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["shareUrl"], "share="
    end
    assert @account.reload.hangar_share_token.present?
  end

  test "POST /me/hangar/share keeps an existing token" do
    token = @account.ensure_hangar_share_token!
    sign_in @account

    assert_api_response :post, 200

    assert_equal token, @account.reload.hangar_share_token
  end

  test "POST /me/hangar/share with OAuth bearer token" do
    assert_api_response :post, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "POST /me/hangar/share returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "POST /me/hangar/share returns 401 when not signed in" do
    assert_api_response :post, 401
  end

  test "DELETE /me/hangar/share removes the share link" do
    @account.ensure_hangar_share_token!
    sign_in @account

    assert_api_response :delete, 204

    assert_nil @account.reload.hangar_share_token
  end

  test "DELETE /me/hangar/share with OAuth bearer token" do
    @account.ensure_hangar_share_token!

    assert_api_response :delete, 204,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "DELETE /me/hangar/share returns 401 for OAuth token with wrong scope" do
    @account.ensure_hangar_share_token!

    assert_api_response :delete, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])

    assert @account.reload.hangar_share_token.present?
  end

  test "DELETE /me/hangar/share returns 401 when not signed in" do
    assert_api_response :delete, 401
  end
end
