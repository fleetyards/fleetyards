# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ComponentClassesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/components/class_filters" do
    get("Component classes") do
      operationId "componentClasses"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
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
    @user = create(:admin_user, resource_access: [:components])
  end

  test "GET /components/class_filters returns the classes in use as filter options" do
    create(:component)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[RSIModular], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "class" })
    end
  end

  test "GET /components/class_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /components/class_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
