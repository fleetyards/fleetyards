# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::UsersFleetsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{user_id}/fleets" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    get("User Fleets list") do
      operationId "userFleets"
      tags "Users"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUserFleets"
      end

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

  test "GET /users/:user_id/fleets returns admin and member fleets" do
    user = create(:user)
    create(:fleet, admins: [user])
    create(:fleet, members: [user])
    sign_in @admin

    assert_api_response :get, 200, path_params: {user_id: user.id}
  end

  test "GET /users/:user_id/fleets returns empty list when user has no fleets" do
    user = create(:user)
    sign_in @admin

    assert_api_response :get, 200, path_params: {user_id: user.id}
  end

  test "GET /users/:user_id/fleets returns 404 for missing user" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {user_id: SecureRandom.uuid}
  end

  test "GET /users/:user_id/fleets returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :get, 401, path_params: {user_id: user.id}
  end

  test "GET /users/:user_id/fleets returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {user_id: user.id}
  end
end
