# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsPositionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/positions" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Positions") do
      operationId "modelPositions"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Positions::ModelPositionsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/positions returns positions" do
    model = create(:model)
    create(:model_position, model: model)
    create(:model_position, :copilot, model: model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 2, parsed_body.count
      assert_equal "Pilot", parsed_body.first["name"]
    end
  end

  # A seat the build dropped keeps its row, and so does its position -- a slot
  # may point at it. Readers only get the ones this build carries.
  test "GET /models/:slug/positions leaves out seats the build does not carry" do
    model = create(:model)
    pilot = create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_seat_pilot")
    dropped = create(:hardpoint, :without_build, parent: model, source: :game_files, sc_name: "hardpoint_seat_gunner")
    create(:model_position, model:, hardpoint: pilot)
    create(:model_position, :copilot, model:, hardpoint: dropped)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal ["Pilot"], parsed_body.pluck("name")
    end
  end

  test "GET /models/:slug/positions returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
