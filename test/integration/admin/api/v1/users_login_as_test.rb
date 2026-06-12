# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::UsersLoginAsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{id}/login-as" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    get("Login as User") do
      operationId "loginAsUser"
      tags "Users"
      produces "application/json"

      response(204, "no content")

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:users])
  end

  test "GET /users/:id/login-as logs the admin in as the user" do
    user = create(:user)
    sign_in @admin

    assert_api_response :get, 204, path_params: {id: user.id}
  end

  test "GET /users/:id/login-as returns 404 for missing id" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /users/:id/login-as returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :get, 401, path_params: {id: user.id}
  end

  test "GET /users/:id/login-as returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: user.id}
  end
end
