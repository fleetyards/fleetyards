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

      parameter ::Shared::V1::Parameters::PageParameter
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ModelQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "containerFit", in: :query,
        schema: ::V1::Schemas::Queries::ContainerFitQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Models
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

  test "GET /models accepts a containerFit map" do
    create_list(:model, 2)

    assert_api_response :get, 200, params: {containerFit: {"16" => 2, "32" => 1}}
  end

  # Plain get rather than the DSL: declaring a 400 here would replace the
  # auto-injected SchemaValidationError response and move the schema.
  test "GET /models rejects a containerFit size outside the standard set" do
    get "/api/v1/models", params: {containerFit: {"7" => 1}}

    assert_response :bad_request
  end

  test "GET /models honours perPage" do
    create_list(:model, 6)

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end
end
