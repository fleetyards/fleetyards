# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsUpgradesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/upgrades" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Upgrades") do
      operationId "modelUpgrades"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ModelUpgrade"}
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/upgrades returns upgrades" do
    model = create(:model, :with_upgrades)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.upgrades.count, parsed_body.count
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /models/:slug/upgrades returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
