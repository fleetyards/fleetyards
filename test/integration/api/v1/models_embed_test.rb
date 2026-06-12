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
    query = models.map { |m| "models[]=#{m.slug}" }.join("&")

    get "/api/v1/models/embed?#{query}"
    assert_equal 200, response.status
    data = JSON.parse(response.body)
    assert_equal 3, data.count
  end
end
