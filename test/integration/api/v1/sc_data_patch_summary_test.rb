# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataPatchSummaryTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PREVIOUS = "1.0.0-live.1"
  CURRENT = "1.0.1-live.2"

  api_path "/sc-data/patch-summary" do
    get("SC Data patch summary") do
      operationId "scDataPatchSummary"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::ScDataPatchSummary
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Rails.cache.clear
  end

  private def model_build(version, model:, **facts)
    create(:model_build, model:, environment: "live", version:, **facts)
  end

  test "GET /sc-data/patch-summary names the new ships and what moved" do
    changed = create(:model, name: "Constellation")
    model_build(PREVIOUS, model: changed, hull_health: 180_844)
    model_build(CURRENT, model: changed, hull_health: 103_004)
    arrived = create(:model, name: "Skylark", first_seen_version: CURRENT)
    model_build(CURRENT, model: arrived)

    assert_api_response :get, 200, api_path: "/sc-data/patch-summary" do
      assert_equal({"environment" => "live", "version" => PREVIOUS}, parsed_body["from"])
      assert_equal({"environment" => "live", "version" => CURRENT}, parsed_body["to"])
      assert_equal ["Skylark"], parsed_body["newShips"].pluck("name")
      assert_equal ["Skylark"], parsed_body["latestArrivals"].pluck("name")
      assert_equal CURRENT, parsed_body["latestArrivalsVersion"]

      change = parsed_body["shipChanges"].sole
      assert_equal "Constellation", change.dig("model", "name")
      assert_equal [{"field" => "hull_health", "from" => 180_844.0, "to" => 103_004.0}], change["fields"]
    end
  end

  test "GET /sc-data/patch-summary answers not found with a single build" do
    model_build(CURRENT, model: create(:model))

    assert_api_response :get, 404, api_path: "/sc-data/patch-summary"
  end
end
