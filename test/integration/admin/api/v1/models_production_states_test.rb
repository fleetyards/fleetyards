# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelsProductionStatesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models/production-states" do
    get("Model Production states") do
      operationId "modelProductionStates"
      tags "Models"
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
    @user = create(:admin_user, resource_access: [:models])
  end

  test "GET /models/production-states returns filter options" do
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /models/production-states returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /models/production-states returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
