# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsWithDocksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/with-docks" do
    get("Models with Docks") do
      operationId "modelsWithDocks"
      tags "Models"
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
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"
      end
    end
  end

  test "GET /models/with-docks returns models with docks" do
    create_list(:model, 6, :with_docks)

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /models/with-docks honours perPage" do
    create_list(:model, 6, :with_docks)

    assert_api_response :get, 200, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end
end
