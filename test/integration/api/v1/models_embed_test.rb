# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsEmbedTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/embed" do
    get("Embed Models") do
      operationId "modelsEmbed"
      tags "Models"
      produces "application/json"

      parameter name: :models, in: :query, schema: {type: :array, items: {type: :string}}, style: :form, explode: true, required: true

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}
      end
    end
  end

  test "GET /models/embed returns embedded models" do
    models = create_list(:model, 3)

    assert_api_response :get, 200, params: {models: models.map(&:slug)} do
      assert_equal 3, parsed_body.count
    end
  end
end
