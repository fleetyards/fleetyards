# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::SessionsConfirmAccessTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions/confirm-access" do
    post("confirm_access session") do
      operationId "confirmAccess"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ConfirmAccessInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "POST /sessions/confirm-access elevates the session" do
    user = create(:user, password: "enterprise")
    sign_in user

    assert_api_response :post, 200, body: {password: "enterprise"}
  end

  test "POST /sessions/confirm-access returns 400 for missing body" do
    user = create(:user, password: "enterprise")
    sign_in user

    assert_api_response :post, 400, body: nil
  end

  test "POST /sessions/confirm-access returns 401 when not signed in" do
    assert_api_response :post, 401, body: {password: "enterprise"}
  end

  test "POST /sessions/confirm-access with OAuth bearer token" do
    user = create(:user, password: "enterprise")

    assert_api_response :post, 200,
      headers: oauth_headers_for(user, scopes: ["public"]),
      body: {password: "enterprise"} do
      assert parsed_body["token"].present?
    end
  end
end
