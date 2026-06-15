# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/options" do
    get("Model Options") do
      operationId "modelOptions"
      tags "ModelsFilters"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelOptions"
      end
    end
  end

  test "GET /filters/models/options returns id/name/slug/media for each model" do
    create_list(:model, 6, :with_store_image)

    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 6, items.count
      assert_equal %w[id name slug media].sort, items.first.keys.sort
    end
  end

  test "GET /filters/models/options filters by nameCont" do
    models = create_list(:model, 6, :with_store_image)

    assert_api_response :get, 200, params: {q: {"nameCont" => models.first.name}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal models.first.name, items.first["name"]
    end
  end
end
