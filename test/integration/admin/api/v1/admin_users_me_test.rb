# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::AdminUsersMeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/admin_users/me" do
    get("My Data") do
      operationId "me"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/AdminUser"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /admin_users/me returns the current admin user" do
    user = create(:admin_user)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal user.username, parsed_body["username"]
    end
  end

  test "GET /admin_users/me returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
