# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ComponentCategoriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/components/category_filters" do
    get("Component categories") do
      operationId "componentCategories"
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

  test "GET /components/category_filters returns the current categories as filter options" do
    create(:component, category: "shieldgenerator", version: ScData::Source.version)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[shieldgenerator], parsed_body.map { |filter| filter["value"] }
      assert_equal "Shield Generators", parsed_body.first["label"]
      assert(parsed_body.all? { |filter| filter["category"] == "category" })
    end
  end

  test "GET /components/category_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /components/category_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
