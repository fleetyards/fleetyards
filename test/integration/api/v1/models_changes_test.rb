# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsChangesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/changes" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Changes") do
      operationId "modelChanges"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Changes::ModelBuildChangesList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/changes returns the newest patch first" do
    model = create(:model)
    record(model, field: "scm_speed", to_version: "4.9.0", recorded_at: 3.months.ago)
    record(model, field: "mass", to_version: "4.10.0", recorded_at: 1.day.ago)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal %w[mass scm_speed], parsed_body.map { |change| change["field"] }
    end
  end

  test "GET /models/:slug/changes leaves out other ships" do
    model = create(:model)
    record(model, field: "mass")
    record(create(:model), field: "scm_speed")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal %w[mass], parsed_body.map { |change| change["field"] }
    end
  end

  # A fact the previous build did not carry has no old value, and null is the
  # honest answer rather than zero.
  test "GET /models/:slug/changes reports a fact that was not there before" do
    model = create(:model)
    record(model, field: "max_speed", old_value: nil, new_value: 1200)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_nil parsed_body.sole["oldValue"]
      assert_equal 1200, parsed_body.sole["newValue"].to_i
    end
  end

  test "GET /models/:slug/changes answers for a ship no patch has changed" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /models/:slug/changes returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end

  private def record(model, field:, to_version: "4.10.0", old_value: 1, new_value: 2, recorded_at: 1.day.ago)
    ModelBuildChange.create!(
      model:, field:, to_version:, old_value:, new_value:, recorded_at:,
      environment: ScData::Source.environment, from_version: "4.9.0"
    )
  end
end
