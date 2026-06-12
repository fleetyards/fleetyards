# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsSlugsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/slugs" do
    get("Available Model-Slugs") do
      operationId "modelsSlugs"
      tags "Models"
      produces "application/json"

      response(200, "successful")
    end
  end

  test "GET /models/slugs returns available slugs" do
    create_list(:model, 6)

    assert_api_response :get, 200
  end
end
