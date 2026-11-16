# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsBodykitsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/bodykits" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Body Kits") do
      operationId "modelBodykits"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Bodykits::ModelBodykitList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  private def bodykit_slot(model, name, stock: nil)
    create(:hardpoint, parent: model, sc_name: name, source: :game_files, types: ["Module"],
      min_size: 1, max_size: 1, port_tags: ["TEST_Shiv_Base"], required_tags: ["TEST_Shiv_Base"], component: stock)
  end

  private def bodykit(name, category: "bodykit")
    create(:component, name:, component_type: "Module", category:, size: "1",
      tags: ["TEST_Shiv_Base"], required_tags: ["TEST_Shiv_Base"])
  end

  test "GET /models/:slug/bodykits lists the body kits each slot takes, the stock one first" do
    model = create(:model)
    stock = bodykit("Slasher Front")
    bodykit("Barebones Front")
    bodykit_slot(model, "hardpoint_front", stock:)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [["hardpoint_front", "Slasher Front", true], ["hardpoint_front", "Barebones Front", false]],
        parsed_body.map { |entry| [entry["slot"], entry.dig("component", "name"), entry["stock"]] }
    end
  end

  test "GET /models/:slug/bodykits leaves out the modules a slot takes" do
    model = create(:model)
    bodykit("Cargo Module", category: "module")
    bodykit_slot(model, "hardpoint_module")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /models/:slug/bodykits answers an unknown ship with not found" do
    assert_api_response :get, 404, path_params: {slug: "unknown"}
  end
end
