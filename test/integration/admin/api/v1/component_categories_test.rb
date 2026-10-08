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

  test "GET /components/category_filters includes components outside the current build" do
    create(:component, category: "prototype", version: "0.0.1-live.1")

    sign_in @user

    assert_api_response :get, 200 do
      assert_includes parsed_body.map { |filter| filter["value"] }, "prototype"
    end
  end

  test "GET /components/category_filters offers the build's category over the column" do
    component = create(:component, :without_build, category: "stale")
    create(:component_build, component:, category: "fresh")

    sign_in @user

    assert_api_response :get, 200 do
      values = parsed_body.map { |filter| filter["value"] }

      assert_includes values, "fresh"
      assert_not_includes values, "stale"
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
