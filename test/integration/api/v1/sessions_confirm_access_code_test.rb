# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::SessionsConfirmAccessCodeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions/confirm-access-code" do
    post("Verify confirm access code") do
      operationId "verifyConfirmAccessCode"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ConfirmAccessCodeInput"}

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request - invalid code") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  def confirm_access_token_for(user, code)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.credentials.confirm_access_secret!, purpose: :access_confirmation)
    verifier.generate({user_id: user.id, code: code}, expires_in: 15.minutes)
  end

  test "POST /sessions/confirm-access-code accepts the valid code" do
    user = create(:user, :oauth_only)
    sign_in user

    token = confirm_access_token_for(user, "123456")
    assert_api_response :post, 200, body: {token: token, confirmationCode: "123456"}
  end

  test "POST /sessions/confirm-access-code returns 400 for invalid code" do
    user = create(:user, :oauth_only)
    sign_in user

    token = confirm_access_token_for(user, "123456")
    assert_api_response :post, 400, body: {token: token, confirmationCode: "000000"}
  end

  test "POST /sessions/confirm-access-code returns 401 when not signed in" do
    assert_api_response :post, 401, body: {token: "invalid", confirmationCode: "000000"}
  end
end
