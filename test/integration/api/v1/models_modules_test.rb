# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsModulesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/modules" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Modules") do
      operationId "modelModules"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModules"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/modules returns modules" do
    model = create(:model, :with_modules)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.modules.count, parsed_body["items"].count
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /models/:slug/modules serialises the slot when set on module_hardpoint" do
    model = create(:model)
    create(:module_hardpoint, model: model, slot: "hardpoint_front_module")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal "hardpoint_front_module", parsed_body["items"].first["slot"]
    end
  end

  test "GET /models/:slug/modules returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
