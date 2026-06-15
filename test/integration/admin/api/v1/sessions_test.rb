# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SessionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/sessions" do
    post("create session") do
      operationId "createSession"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SessionInput"}

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/AdminUser"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      response(200, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "POST /sessions creates a session for the admin" do
    user = create(:admin_user, password: "enterprise")

    assert_api_response :post, 200, body: {login: user.username, password: "enterprise"}
  end

  test "POST /sessions returns 400 when body is missing" do
    assert_api_response :post, 400, body: nil
  end

  test "DELETE /sessions signs out the current admin" do
    user = create(:admin_user)
    sign_in user

    assert_api_response :delete, 200
  end

  test "DELETE /sessions returns 401 when no admin signed in" do
    assert_api_response :delete, 401
  end
end
