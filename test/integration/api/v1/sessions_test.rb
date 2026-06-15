# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SessionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions" do
    post("create session") do
      operationId "createSession"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SessionInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  # POST /sessions
  test "POST /sessions signs the user in" do
    user = create(:user, password: "enterprise")

    assert_api_response :post, 200, body: {login: user.username, password: "enterprise"}
  end

  test "POST /sessions returns 400 for missing body" do
    assert_api_response :post, 400, body: nil
  end

  # DELETE /sessions
  test "DELETE /sessions signs the user out" do
    user = create(:user)
    sign_in user

    assert_api_response :delete, 200
  end

  test "DELETE /sessions returns 401 when not signed in" do
    assert_api_response :delete, 401
  end
end
