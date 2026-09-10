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
    create(:dock, :with_dimensions, model: carrier, dock_type: :hangar)
    too_small = create(:model, name: "Small Carrier")
    create(:dock, model: too_small, dock_type: :hangar, length: 8.0, beam: 6.0, height: 4.0)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, ground: false)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      names = parsed_body["carriedBy"].map { |entry| entry["name"] }

      assert_includes names, carrier.name
      assert_not_includes names, too_small.name
      assert_equal "hangar", parsed_body["carriedBy"].first["dockType"]
    end
  end

  # A ground vehicle belongs in a garage, not on a landing pad.
  test "GET /models/:slug does not offer a ship dock to a ground vehicle" do
    carrier = create(:model)
    create(:dock, :with_dimensions, model: carrier, dock_type: :hangar)

    buggy = create(:model, length: 4.0, beam: 2.0, height: 2.0, ground: true)

    assert_api_response :get, 200, path_params: {slug: buggy.slug} do
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
