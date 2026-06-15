# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsLoanersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/loaners" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Loaners") do
      operationId "modelLoaners"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/loaners returns loaners" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/loaners returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
