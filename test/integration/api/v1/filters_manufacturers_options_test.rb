# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersManufacturersOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/manufacturers/options" do
    get("Manufacturer Options") do
      operationId "manufacturerOptions"
      tags "ManufacturersFilters"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Manufacturer.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ManufacturerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ManufacturerOptions"
      end
    end
  end

  test "GET /filters/manufacturers/options returns id/name/slug/logo for each manufacturer" do
    create_list(:manufacturer, 6, :with_logo, :with_models)

    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 6, items.count
      assert_equal %w[id name slug logo].sort, items.first.keys.sort
    end
  end

  test "GET /filters/manufacturers/options filters by nameCont" do
    manufacturers = create_list(:manufacturer, 6, :with_logo, :with_models)

    assert_api_response :get, 200, params: {q: {"nameCont" => manufacturers.first.name}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal manufacturers.first.name, items.first["name"]
    end
  end
end
