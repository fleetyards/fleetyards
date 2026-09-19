# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::BlueprintCraftableTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/blueprints/craftable_type_filters" do
    get("Blueprint craftable types") do
      operationId "blueprintCraftableTypes"
      tags "Blueprints"
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
    @user = create(:admin_user, resource_access: [:blueprints])
  end

  # Offered whether or not anything currently makes one: all three catalogues
  # are always a question worth asking, and a load can empty one of them.
  test "GET /blueprints/craftable_type_filters returns every catalogue as a filter option" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal ::Blueprint::CRAFTABLE_TYPES, parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "craftable_type" })
    end
  end

  test "GET /blueprints/craftable_type_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /blueprints/craftable_type_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
