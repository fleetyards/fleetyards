# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeRsiVerificationCheckTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/rsi-verification/check" do
    post("Check the RSI citizen page for the verification token") do
      operationId "checkMyRsiVerification"
      tags "Me RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::UserRsiVerification
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user, rsi_handle: "TestPilot")
    UserRsiVerificationJob.clear
  end

  test "POST /me/rsi-verification/check queues a check" do
    sign_in @user

    assert_api_response :post, 200

    assert_equal "pending", response.parsed_body["status"]
    assert response.parsed_body["nextCheckAt"].present?
    assert_equal 1, UserRsiVerificationJob.jobs.size
    assert_equal [@user.id, UserRsiVerification.generation_of(@user.reload.rsi_verification_checked_at)],
      UserRsiVerificationJob.jobs.first["args"]
  end

  test "POST /me/rsi-verification/check inside the cooldown does not reach RSI again" do
    sign_in @user
    @user.update_columns(rsi_verification_checked_at: Time.current, rsi_verification_status: :token_missing) # rubocop:disable Rails/SkipsModelValidations

    assert_api_response :post, 200

    assert_equal "token_missing", response.parsed_body["status"]
    assert_empty UserRsiVerificationJob.jobs
  end

  test "POST /me/rsi-verification/check does not check a handle that is already verified" do
    @user.verify_rsi_handle("TestPilot", via: :citizenid)
    @user.save!
    sign_in @user

    assert_api_response :post, 200

    assert_equal true, response.parsed_body["verified"]
    assert_empty UserRsiVerificationJob.jobs
  end

  test "POST /me/rsi-verification/check needs a handle" do
    @user.update!(rsi_handle: nil)
    sign_in @user

    assert_api_response :post, 400

    assert_equal "validation_error.user_rsi_verification.check", response.parsed_body["code"]
  end

  test "POST /me/rsi-verification/check returns 401 when not signed in" do
    assert_api_response :post, 401
  end
end
