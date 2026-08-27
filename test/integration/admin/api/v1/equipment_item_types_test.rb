# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::EquipmentItemTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/equipment/item_type_filters" do
    get("Equipment item types") do
      operationId "equipmentItemTypes"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:equipment])
  end

  test "GET /equipment/item_type_filters returns the item types in use as filter options" do
    create(:equipment)
    create(:equipment, :attachment)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[assault_rifle weapon_scope], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "item_type" })
    end
  end

  test "GET /equipment/item_type_filters skips hidden gear" do
    create(:equipment, :hidden)

    sign_in @user

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /equipment/item_type_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /equipment/item_type_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
