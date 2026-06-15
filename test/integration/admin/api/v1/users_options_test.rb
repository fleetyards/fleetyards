# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::UsersOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/options" do
    get("User Options") do
      operationId "userOptions"
      tags "Users"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/UserQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/UserOptions"
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

  test "GET /users/options returns id/username for each user" do
    create_list(:user, 6)
    sign_in @admin

    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 6, items.count
      assert_equal %w[id username].sort, items.first.keys.sort
    end
  end

  test "GET /users/options returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /users/options returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
