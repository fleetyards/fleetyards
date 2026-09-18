# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersBlueprintsMaterialsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/blueprints/materials" do
    get("Blueprint materials filter") do
      operationId "filtersBlueprintsMaterials"
      tags "Filters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    @iron = create(:commodity, name: "Iron")
    @blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, build: @blueprint.build)
    create(:blueprint_cost_option, slot:, commodity: @iron)
  end

  test "GET /filters/blueprints/materials lists the materials recipes ask for" do
    assert_api_response :get, 200 do
      assert_equal ["Iron"], parsed_body.pluck("label")
      assert_equal [@iron.slug], parsed_body.pluck("value")
    end
  end

  # 37 of the 232 commodities appear in a recipe. A select built from the
  # catalogue would offer 195 options that can only ever come back empty.
  test "GET /filters/blueprints/materials leaves out a commodity no recipe uses" do
    create(:commodity, name: "Unused Ore")

    assert_api_response :get, 200 do
      assert_equal ["Iron"], parsed_body.pluck("label")
    end
  end

  # The recipe belongs to a build, so a material only an older build asked for
  # is not a material the current catalogue can be filtered by.
  test "GET /filters/blueprints/materials ignores a material only another build uses" do
    old = create(:blueprint, :without_build, version: nil)
    build = old.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(
      :blueprint_cost_option,
      slot: create(:blueprint_cost_slot, build:),
      commodity: create(:commodity, name: "Retired Ore")
    )

    assert_api_response :get, 200 do
      assert_equal ["Iron"], parsed_body.pluck("label")
    end
  end
end
