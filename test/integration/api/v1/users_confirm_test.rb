# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersConfirmTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/confirm" do
    post("Confirm Account") do
      operationId "confirmAccount"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ConfirmAccountInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end
    end
  end

  test "POST /users/confirm confirms the account" do
    token = SecureRandom.hex(16)
    create(:user, confirmed_at: nil, confirmation_token: token)

    assert_api_response :post, 200, body: {token: token}
  end

  test "POST /users/confirm returns 400 for invalid token" do
    assert_api_response :post, 400, body: {token: "invalid"}
  end
end
