# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PasswordTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/password" do
    put("Update password") do
      operationId "updatePassword"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/PasswordInput"}

      security [{SessionCookie: []}]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/password/request" do
    post("Request Password reset") do
      operationId "requestPasswordReset"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/PasswordRequestInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end
    end
  end

  api_path "/password/{token}" do
    parameter name: :token, in: :path, schema: {type: :string}, required: true

    put("Update Password with Token") do
      operationId "updatePasswordWithToken"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/PasswordInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end
    end
  end

  # PUT /password
  test "PUT /password updates the password for the signed-in user" do
    user = create(:user, password: "enterprise")
    sign_in user

    body = {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
    assert_api_response :put, 200, body: body
  end

  test "PUT /password returns 400 for missing body" do
    user = create(:user, password: "enterprise")
    sign_in user

    assert_api_response :put, 400, body: nil
  end

  test "PUT /password returns 401 when not signed in" do
    body = {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
    assert_api_response :put, 401, body: body
  end

  # POST /password/request
  test "POST /password/request triggers a reset email" do
    user = create(:user)

    assert_api_response :post, 200, body: {email: user.email}
  end

  test "POST /password/request returns 400 for missing body" do
    assert_api_response :post, 400, body: nil
  end

  # PUT /password/{token}
  test "PUT /password/:token updates password with valid reset token" do
    user = create(:user)
    token = user.send_reset_password_instructions

    body = {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
    assert_api_response :put, 200, path_params: {token: token}, body: body
  end

  test "PUT /password/:token returns 400 for unknown token" do
    body = {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
    assert_api_response :put, 400, path_params: {token: "unknown"}, body: body
  end

  test "PUT /password/:token returns 400 for missing body" do
    user = create(:user)
    token = user.send_reset_password_instructions

    assert_api_response :put, 400, path_params: {token: token}, body: nil
  end
end
