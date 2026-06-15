# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelPaintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/model-paints" do
    get("Model Paints List") do
      operationId "paints"
      tags "ModelPaints"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPaint.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPaintQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaint"}
      end
    end
  end

  setup do
    @model_paints = create_list(:model_paint, 3)
  end

  test "GET /model-paints lists all model paints" do
    assert_api_response :get, 200 do
      assert_equal 3, parsed_body.count
    end
  end

  test "GET /model-paints filters by modelSlugEq query" do
    assert_api_response :get, 200, params: {q: {"modelSlugEq" => @model_paints.first.model.slug}} do
      assert_equal 1, parsed_body.count
      assert_equal @model_paints.first.name, parsed_body.first["name"]
    end
  end

  test "GET /model-paints paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body.count
    end
  end
end
