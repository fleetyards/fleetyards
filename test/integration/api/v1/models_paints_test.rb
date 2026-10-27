# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsPaintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/paints" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Paints") do
      operationId "modelPaints"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Paints::ModelPaintsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/paints returns paints" do
    model = create(:model, :with_paints)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.paints.count, parsed_body.count
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /models/:slug/paints carries the map that repaints the textured holo" do
    model = create(:model)
    paint = create(:model_paint, model:)
    paint.holo_texture.attach(io: StringIO.new("webp"), filename: "flight_textured_gladiuspirate.webp")
    create(:model_paint, model:)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      textures = parsed_body.to_h { |entry| [entry["id"], entry.dig("media", "holoTexture")] }

      assert_match(/flight_textured_gladiuspirate\.webp/, textures[paint.id])
      assert_equal 1, textures.values.compact.size
    end
  end

  test "GET /models/:slug/paints returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
