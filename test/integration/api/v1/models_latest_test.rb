# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsLatestTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/latest" do
    get("Latest Models") do
      operationId "modelsLatest"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}
      end
    end
  end

  test "GET /models/latest returns the latest models" do
    create_list(:model, 3)

    assert_api_response :get, 200
  end
end
