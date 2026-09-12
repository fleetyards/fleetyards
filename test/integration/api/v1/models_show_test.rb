# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::ModelExtended
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug names the ships that can carry it" do
    carrier = create(:model, name: "Big Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)
    too_small = create(:model, name: "Small Carrier")
    create(:dock, parent: too_small, dock_type: :hangar, length: 8.0, beam: 6.0, height: 4.0)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      names = parsed_body["carriedBy"].map { |entry| entry["name"] }

      assert_includes names, carrier.name
      assert_not_includes names, too_small.name
      assert_equal "hangar", parsed_body["carriedBy"].first["dockType"]
    end
  end

  # The Galaxy's med bay carries a vehicle lift and its refinery does not, so a
  # berth that arrives with a module counts -- and says which module, because
  # the carrier is conditional on the owner having mounted it.
  test "GET /models/:slug names a carrier whose berth comes with a module" do
    carrier = create(:model, name: "Modular Carrier")
    model_module = create(:model_module, name: "Med Bay Module")
    create(:module_hardpoint, model: carrier, model_module: model_module)
    create(:dock, :with_dimensions, parent: model_module, dock_type: :hangar)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entry = parsed_body["carriedBy"].find { |item| item["name"] == carrier.name }

      assert_not_nil entry
      assert_equal "Med Bay Module", entry["moduleName"]
    end
  end

  test "GET /models/:slug leaves moduleName off a berth built into the hull" do
    carrier = create(:model, name: "Fixed Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entry = parsed_body["carriedBy"].find { |item| item["name"] == carrier.name }

      assert_not_nil entry
      assert_nil entry["moduleName"]
    end
  end

  # A hover bike is size vehicle and ground false, so `ground` would have sent it
  # to a hangar instead of a bay.
  test "GET /models/:slug offers a bay to a hover bike" do
    carrier = create(:model, name: "Bay Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    bike = create(:model, length: 4.0, beam: 2.0, height: 2.0, size: "vehicle", ground: false)

    assert_api_response :get, 200, path_params: {slug: bike.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # An unmeasured hull is not compared at all: zeroes would satisfy every upper
  # bound and the answer would be confident and wrong.
  test "GET /models/:slug carries nothing for a model without dimensions" do
    carrier = create(:model)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)

    unmeasured = create(:model, length: 0, beam: 0, height: 0, size: "small")

    assert_api_response :get, 200, path_params: {slug: unmeasured.slug} do
      assert_empty parsed_body["carriedBy"]
    end
  end

  # A ship in a garage is the case that stays impossible.
  test "GET /models/:slug does not offer a garage to a ship" do
    carrier = create(:model)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    ship = create(:model, length: 4.0, beam: 2.0, height: 2.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: ship.slug} do
      assert_empty parsed_body["carriedBy"]
    end
  end

  test "GET /models/:slug returns the model" do
    model = create(:model, :with_description, :with_store_image, :with_fleetchart_image)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
