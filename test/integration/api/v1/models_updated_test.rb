# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsUpdatedTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/updated" do
    get("Updated Models") do
      operationId "modelsUpdated"
      tags "Models"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string, format: :datetime}, required: false
      parameter name: :to, in: :query, schema: {type: :string, default: :now, format: :datetime}, required: false

      response(200, "successful")

      response(304, "not modified")
    end
  end

  test "GET /models/updated returns updated models" do
    create_list(:model, 3)

    assert_api_response :get, 200, params: {from: 1.day.ago.iso8601}
  end

  test "GET /models/updated returns 304 when nothing modified" do
    assert_api_response :get, 304
  end
end
