# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SessionsConfirmAccessCodeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions/confirm-access-code" do
    post("Verify confirm access code") do
      operationId "verifyConfirmAccessCode"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::ConfirmAccessCodeInput

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema ::V1::Schemas::StandardMessage
      end

      response(400, "bad request - invalid code") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  # Issues a real token through the email endpoint with the emailed code pinned.
  def confirm_access_token_for(code)
    SecureRandom.stubs(:random_number).with(10**6).returns(code.to_i)
    post "/api/v1/sessions/confirm-access-email", as: :json
    SecureRandom.unstub(:random_number)
    response.parsed_body["token"]
  end

  test "POST /sessions/confirm-access-code accepts the valid code" do
    user = create(:user, :oauth_only)
    sign_in user

    token = confirm_access_token_for("123456")
    assert_api_response :post, 200, body: {token: token, confirmationCode: "123456"}
  end

  test "POST /sessions/confirm-access-code returns 400 for invalid code" do
    user = create(:user, :oauth_only)
    sign_in user

    token = confirm_access_token_for("123456")
    assert_api_response :post, 400, body: {token: token, confirmationCode: "000000"}
  end

  test "POST /sessions/confirm-access-code returns 401 when not signed in" do
    assert_api_response :post, 401, body: {token: "invalid", confirmationCode: "000000"}
  end

  test "POST /sessions/confirm-access-email does not reveal the code in its token" do
    user = create(:user, :oauth_only)
    sign_in user

    token = confirm_access_token_for("123456")

    assert_not_includes Base64.decode64(token.split("--").first), "123456"
  end

  test "POST /sessions/confirm-access-code refuses an access-confirmation token in place of a code token" do
    user = create(:user, :oauth_only)
    sign_in user
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.credentials.confirm_access_secret!, purpose: :access_confirmation)

    post "/api/v1/sessions/confirm-access-code", params: {token: verifier.generate(user.id), confirmationCode: "123456"}, as: :json

    assert_response :bad_request
  end
end
