# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ComponentItemTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/components/item_type_filters" do
    get("Component item types") do
      operationId "componentItemTypes"
      tags "Components"
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
    @user = create(:admin_user, resource_access: [:components])
  end

  # The list is the hardcoded set of types, not what the table happens to hold,
  # so an empty database still offers every one of them.
  test "GET /components/item_type_filters returns every item type as a filter option" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal Component.item_types, parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "item_type" })
    end
  end

  test "GET /components/item_type_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /components/item_type_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
