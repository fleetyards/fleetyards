# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsPatchChangesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/patch-changes" do
    get("Stats Patch Changes") do
      operationId "patchChanges"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/patch-changes returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/patch-changes ranks ships by how much the build changed" do
    reworked = create(:model)
    tweaked = create(:model)
    record(reworked, fields: %w[scm_speed max_speed mass])
    record(tweaked, fields: %w[mass])

    assert_api_response :get, 200 do
      assert_equal [reworked.name, tweaked.name], parsed_body.map { |point| point["label"] }
      assert_equal [3, 1], parsed_body.map { |point| point["count"] }
    end
  end

  # The chart is about the build we are on, not every build we ever recorded.
  test "GET /stats/patch-changes leaves out earlier patches" do
    model = create(:model)
    record(model, fields: %w[mass], to_version: "4.9.0")

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/patch-changes drops a ship that is no longer visible" do
    hidden = create(:model, hidden: true)
    record(hidden, fields: %w[mass])

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  private def record(model, fields:, to_version: ScData::Source.version)
    fields.each do |field|
      ModelBuildChange.create!(
        model:, field:, to_version:, old_value: 1, new_value: 2,
        recorded_at: 1.day.ago,
        environment: ScData::Source.environment, from_version: "4.9.0"
      )
    end
  end
end
