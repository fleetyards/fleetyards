# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersAccountTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/account" do
    put("Update My Account") do
      operationId "updateAccount"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::AccountUpdateInput
      parameter name: "X-Access-Confirmation", in: :header, schema: {type: :string},
        description: "Access confirmation token obtained from confirm-access endpoint. Required when using OAuth/OpenID authentication.",
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"
      end

      response(400, "bad request") do
        schema "$ref" => "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  def confirm_access!(password)
    post confirm_access_api_v1_sessions_path, params: {password: password}, as: :json
  end

  test "PUT /users/account updates account" do
    user = create(:user, password: "enterprise")
    sign_in user
    confirm_access!("enterprise")

    assert_api_response :put, 200, body: {username: "TestUser"} do
      assert_equal "TestUser", parsed_body["username"]
    end
  end

  test "PUT /users/account returns 400 for invalid input" do
    user = create(:user, password: "enterprise")
    sign_in user
    confirm_access!("enterprise")

    assert_api_response :put, 400, body: {username: ""}
  end

  test "PUT /users/account returns 401 when not signed in" do
    assert_api_response :put, 401, body: {username: "TestUser"}
  end

  test "PUT /users/account with OAuth bearer + access confirmation" do
    user = create(:user)
    headers = oauth_headers_for(user, scopes: ["profile:write"], with_access_confirmation: true)

    assert_api_response :put, 200, headers: headers, body: {username: "TestUser"}
  end

  test "PUT /users/account returns 400 for OAuth bearer without X-Access-Confirmation" do
    user = create(:user)

    assert_api_response :put, 400, headers: oauth_headers_for(user, scopes: ["profile:write"]), body: {username: "TestUser"}
  end

  test "PUT /users/account sets an address on a placeholder account without access confirmation" do
    user = create(:user, email: "#{SecureRandom.uuid}@#{User::PLACEHOLDER_EMAIL_DOMAIN}")
    sign_in user

    assert_api_response :put, 200, body: {email: "pilot@example.org"}

    user.reload

    assert_equal "pilot@example.org", user.unconfirmed_email
    assert_predicate user, :placeholder_email?
  end

  test "PUT /users/account still needs access confirmation for anything else on a placeholder account" do
    user = create(:user, email: "#{SecureRandom.uuid}@#{User::PLACEHOLDER_EMAIL_DOMAIN}")
    sign_in user

    assert_api_response :put, 400, body: {email: "pilot@example.org", username: "TestUser"} do
      assert_equal "requires_access_confirmation", parsed_body["code"]
    end
  end

  test "PUT /users/account still needs access confirmation for a placeholder account over OAuth" do
    user = create(:user, email: "#{SecureRandom.uuid}@#{User::PLACEHOLDER_EMAIL_DOMAIN}")

    assert_api_response :put, 400, headers: oauth_headers_for(user, scopes: ["profile:write"]), body: {email: "pilot@example.org"}
  end

  test "PUT /users/account still needs access confirmation to change a real address" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 400, body: {email: "pilot@example.org"} do
      assert_equal "requires_access_confirmation", parsed_body["code"]
    end
  end
end
