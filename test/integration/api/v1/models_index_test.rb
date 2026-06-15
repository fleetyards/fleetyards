# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models" do
    get("Models List") do
      operationId "models"
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
      parameter name: "containerFit", in: :query,
        schema: {type: :object, additionalProperties: {type: :integer}},
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"
      end
    end
  end

  test "GET /models returns a list of models" do
    create_list(:model, 6)

    assert_api_response :get, 200 do
      assert_equal 6, parsed_body["items"].count
    end
  end

  test "GET /models filters by nameOrDescriptionCont" do
    models = create_list(:model, 6)

    assert_api_response :get, 200, params: {q: {"nameOrDescriptionCont" => models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /models honours perPage" do
    create_list(:model, 6)

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end
end
