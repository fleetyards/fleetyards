# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ManufacturersWithModelsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

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

  test "GET /manufacturers/with-models returns successfully" do
    assert_api_response :get, 200
  end
end
