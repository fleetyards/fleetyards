# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::SessionsConfirmAccessEmailTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions/confirm-access-email" do
    post("Send confirm access email with code") do
      operationId "sendConfirmAccessEmail"
      tags "Sessions"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ConfirmAccessEmailResponse"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - user has password") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "POST /sessions/confirm-access-email sends a code for oauth-only users" do
    user = create(:user, :oauth_only)
    sign_in user

    assert_api_response :post, 200, body: {}
  end

  test "POST /sessions/confirm-access-email returns 401 when not signed in" do
    assert_api_response :post, 401, body: {}
  end

  test "POST /sessions/confirm-access-email returns 403 for users with a password" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    sign_in user

    assert_api_response :post, 403, body: {}
  end
end
