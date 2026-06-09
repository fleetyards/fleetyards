# frozen_string_literal: true

require_relative "../../openapi_helper"

class Oauth::AuthorizeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"oauth/v1/schema"

  api_path "/authorize" do
    get("Pre-authorize OAuth application") do
      operationId "oauthPreAuthorize"
      tags "OAuth"
      produces "application/json"

      parameter name: :client_id, in: :query, schema: {type: :string}, required: true
      parameter name: :redirect_uri, in: :query, schema: {type: :string}, required: true
      parameter name: :response_type, in: :query, schema: {type: :string}, required: true
      parameter name: :scope, in: :query, schema: {type: :string}, required: true
      parameter name: :state, in: :query, schema: {type: :string}, required: false
      parameter name: :code_challenge, in: :query, schema: {type: :string}, required: false
      parameter name: :code_challenge_method, in: :query, schema: {type: :string}, required: false

      security [{SessionCookie: []}]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthPreAuthorization"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    post("Authorize OAuth application") do
      operationId "oauthAuthorize"
      tags "OAuth"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}

      security [{SessionCookie: []}]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthAuthorizationRedirect"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Deny OAuth authorization") do
      operationId "oauthDeny"
      tags "OAuth"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}

      security [{SessionCookie: []}]

      response(400, "denied") do
        schema "$ref": "#/components/schemas/OauthAuthorizationRedirect"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
    @oauth_application = create(
      :oauth_application,
      owner: @user,
      confidential: false,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html"
    )
  end

  def auth_query
    {
      client_id: @oauth_application.uid,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html",
      response_type: "code",
      scope: "public profile:read",
      state: "test-state",
      code_challenge: "test-challenge",
      code_challenge_method: "S256"
    }
  end

  def auth_body
    {
      clientId: @oauth_application.uid,
      redirectUri: "http://localhost:3000/oauth2-redirect.html",
      responseType: "code",
      scope: "public profile:read",
      state: "test-state",
      codeChallenge: "test-challenge",
      codeChallengeMethod: "S256"
    }
  end

  test "GET /authorize returns pre-authorization metadata for the signed-in user" do
    sign_in @user

    assert_api_response :get, 200, params: auth_query do
      assert_equal @oauth_application.uid, parsed_body["clientId"]
      assert_equal @oauth_application.name, parsed_body["clientName"]
      assert_equal "public profile:read", parsed_body["scope"]
      assert_kind_of Array, parsed_body["scopes"]
      assert_includes parsed_body["scopes"].first.keys, "name"
      assert_includes parsed_body["scopes"].first.keys, "description"
    end
  end

  test "GET /authorize returns 401 when no user is signed in" do
    new_app = create(
      :oauth_application,
      confidential: false,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html"
    )

    params = auth_query.merge(client_id: new_app.uid)

    assert_api_response :get, 401, params: params
  end

  test "POST /authorize approves and returns a redirect with code" do
    sign_in @user

    assert_api_response :post, 200, body: auth_body do
      assert_equal "redirect", parsed_body["status"]
      assert_includes parsed_body["redirect_uri"], "code="
    end
  end

  test "POST /authorize returns 401 when no user is signed in" do
    new_app = create(
      :oauth_application,
      confidential: false,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html"
    )

    assert_api_response :post, 401, body: auth_body.merge(clientId: new_app.uid)
  end

  test "DELETE /authorize denies with a redirect" do
    sign_in @user

    assert_api_response :delete, 400, body: auth_body do
      assert_equal "redirect", parsed_body["status"]
      assert_includes parsed_body["redirect_uri"], "error=access_denied"
    end
  end

  test "DELETE /authorize returns 401 when no user is signed in" do
    new_app = create(
      :oauth_application,
      confidential: false,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html"
    )

    assert_api_response :delete, 401, body: auth_body.merge(clientId: new_app.uid)
  end
end
