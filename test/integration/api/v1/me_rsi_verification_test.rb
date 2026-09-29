# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeRsiVerificationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/rsi-verification" do
    get("Show the RSI handle verification") do
      operationId "myRsiVerification"
      tags "Me RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::UserRsiVerification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Issue a new RSI handle verification token") do
      operationId "createMyRsiVerification"
      tags "Me RSI Verification"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(201, "created") do
        schema ::V1::Schemas::UserRsiVerification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Remove the RSI handle verification") do
      operationId "destroyMyRsiVerification"
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
  end

  test "GET /me/rsi-verification answers with every key" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal "TestPilot", parsed_body["handle"]
      assert_equal @user.rsi_verification_token, parsed_body["token"]
      assert_equal false, parsed_body["verified"]
      assert parsed_body.key?("verifiedVia")
      assert parsed_body.key?("status")
    end
  end

  test "GET /me/rsi-verification returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "POST /me/rsi-verification rotates the token" do
    sign_in @user
    token = @user.rsi_verification_token

    assert_api_response :post, 201

    assert_not_equal token, @user.reload.rsi_verification_token
    assert_equal @user.rsi_verification_token, response.parsed_body["token"]
  end

  test "POST /me/rsi-verification returns 401 when not signed in" do
    assert_api_response :post, 401
  end

  test "DELETE /me/rsi-verification unlocks a handle proved through the bio and keeps the token" do
    @user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    @user.save!
    token = @user.rsi_verification_token
    sign_in @user

    assert_api_response :delete, 200

    @user.reload
    assert_not @user.rsi_handle_verified?
    assert_nil @user.rsi_handle_verified_via
    assert_equal "TestPilot", @user.rsi_handle
    assert_equal token, @user.rsi_verification_token
  end

  test "DELETE /me/rsi-verification leaves a Citizen iD verification to the disconnect" do
    @user.verify_rsi_handle("TestPilot", via: :citizenid)
    @user.save!
    sign_in @user

    assert_api_response :delete, 400

    assert_equal "validation_error.user_rsi_verification.destroy", response.parsed_body["code"]
    assert @user.reload.rsi_handle_verified?
  end

  test "DELETE /me/rsi-verification returns 401 when not signed in" do
    assert_api_response :delete, 401
  end
end
