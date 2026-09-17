# frozen_string_literal: true

require "openapi_helper"

class Api::V1::BlueprintsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/blueprints/{slug}" do
    get("Blueprint detail") do
      operationId "blueprint"
      tags "Blueprints"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Blueprint
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("blueprints")

    @blueprint = create(:blueprint, name: "Bulldog Repeater", sc_key: "bp_craft_behr_repeater_s3")
    @slot = create(:blueprint_cost_slot, build: @blueprint.build, name: "Frame")
  end

  test "GET /blueprints/{slug} returns the recipe" do
    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      assert_equal "Bulldog Repeater", parsed_body["name"]
      assert_equal "behr-repeater-s3", parsed_body["slug"]
    end
  end

  test "GET /blueprints/{slug} carries every slot with its materials and stats" do
    commodity = create(:commodity, name: "Iron")
    create(:blueprint_cost_option, slot: @slot, commodity:)
    create(:blueprint_cost_modifier, slot: @slot, name: "Impact Force")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      slot = parsed_body["costSlots"].first

      assert_equal "Frame", slot["name"]
      assert_equal "Iron", slot["options"].first.dig("commodity", "name")
      assert_equal "Impact Force", slot["modifiers"].first["name"]
    end
  end

  # A material the commodity catalogue has no row for still has to say which
  # material it is, rather than rendering a nameless cost line.
  test "GET /blueprints/{slug} names a material that resolves to no commodity" do
    create(:blueprint_cost_option, slot: @slot, commodity: nil, commodity_key: "items_commodities_unknown")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      option = parsed_body["costSlots"].first["options"].first

      assert_nil option["commodity"]
      assert_equal "items_commodities_unknown", option["commodityKey"]
    end
  end

  test "GET /blueprints/{slug} says where the recipe comes from" do
    create(:blueprint_source, build: @blueprint.build, org_name: "Foxwell Enforcement")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      assert_equal false, parsed_body["sourceUnknown"]
      assert_equal "Foxwell Enforcement", parsed_body["sources"].first["orgName"]
    end
  end

  # 901 of the 1607 recipes in the current build appear in no reward pool. An
  # empty `sources` alone reads as a gap in our data rather than in the game's.
  test "GET /blueprints/{slug} says outright when nothing states a source" do
    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      assert_equal true, parsed_body["sourceUnknown"]
      assert_empty parsed_body["sources"]
    end
  end

  test "GET /blueprints/{slug} 404s for a slug nobody has" do
    assert_api_response :get, 404, params: {slug: "no-such-blueprint"}
  end

  test "GET /blueprints/{slug} is forbidden while the flag is off" do
    Flipper.disable("blueprints")

    assert_api_response :get, 403, params: {slug: @blueprint.slug}
  end
end
