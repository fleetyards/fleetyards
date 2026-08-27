# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::EquipmentTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/equipment/type_filters" do
    get("Equipment types") do
      operationId "equipmentTypes"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FilterOptionsList"
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
    @user = create(:admin_user, resource_access: [:equipment])
  end

  test "GET /equipment/type_filters returns the types in use as filter options" do
    create(:equipment)
    create(:equipment, :armor)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[armor weapon], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "equipment_type" })
    end
  end

  test "GET /equipment/type_filters skips hidden gear" do
    create(:equipment, :hidden)

    sign_in @user

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /equipment/type_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /equipment/type_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
