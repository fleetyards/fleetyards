# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ManufacturersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/manufacturers" do
    get("Manufacturers list") do
      operationId "manufacturers"
      tags "Manufacturers"
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
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"
      end
    end
  end

  api_path "/manufacturers/with-models" do
    get("with_models manufacturer") do
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"
      end
    end
  end

  setup do
    @manufacturers = create_list(:manufacturer, 2)
    @manufacturers_with_models = create_list(:manufacturer, 5, :with_models)
  end

  test "GET /manufacturers lists all manufacturers" do
    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 7, items.count
    end
  end

  test "GET /manufacturers filters by withModels query" do
    assert_api_response :get, 200, params: {q: {"withModels" => true}} do
      items = parsed_body["items"]
      assert_equal 5, items.count
    end
  end

  test "GET /manufacturers paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      items = parsed_body["items"]
      assert_equal 2, items.count
    end
  end

  test "GET /manufacturers/with-models returns successfully" do
    assert_api_response :get, 200
  end
end
