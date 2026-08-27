# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersComponentsCategoriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/categories" do
    get("Components Categories Filters") do
      operationId "componentCategoriesFilters"
      tags "ComponentsFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    @version = Rails.configuration.sc_data[:version]

    create(:component, category: "shieldgenerator", version: @version)
    create(:component, category: "weapons", version: @version)
    create(:component, category: "weapons", version: @version)
  end

  test "GET /filters/components/categories returns one option per category" do
    assert_api_response :get, 200 do
      assert_equal %w[shieldgenerator weapons], parsed_body.map { |filter| filter["value"] }
      assert_equal "Shield Generators", parsed_body.first["label"]
      assert_equal "category", parsed_body.first["category"]
    end
  end

  test "GET /filters/components/categories excludes older game versions" do
    create(:component, category: "cooler", version: "0.0.1-live.1")

    assert_api_response :get, 200 do
      assert_equal %w[shieldgenerator weapons], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/components/categories falls back to the raw value without a translation" do
    create(:component, category: "newfangleddrive", version: @version)

    assert_api_response :get, 200 do
      option = parsed_body.find { |filter| filter["value"] == "newfangleddrive" }

      assert_equal "Newfangleddrive", option["label"]
    end
  end
end
