# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ResourceAccessCatalogTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/resource-access-catalog" do
    get("Resource Access Catalog") do
      operationId "resourceAccessCatalog"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminResourceAccessGroupsList"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /resource-access-catalog returns the grouped privilege catalog" do
    sign_in create(:admin_user)

    assert_api_response :get, 200 do
      keys = parsed_body.map { |group| group["key"] }

      assert_equal AdminUser.privilege_groups.map { |group| group[:key] }, keys
      ship_data = parsed_body.find { |group| group["key"] == "ship_data" }
      assert_includes ship_data["privileges"], "models"
    end
  end

  test "GET /resource-access-catalog returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
