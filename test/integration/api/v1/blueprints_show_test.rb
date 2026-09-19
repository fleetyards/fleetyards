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

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
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

  # The schema calls the two ramp figures numbers, and the page does arithmetic
  # on them to place a marker. A `decimal` column renders as a JSON string
  # unless it is asked otherwise, which is valid JSON, passes the schema check,
  # and reaches the client typed `number` while holding "0.8".
  test "GET /blueprints/{slug} renders the ramp figures as numbers" do
    create(
      :blueprint_cost_modifier,
      slot: @slot,
      modifier_at_start: 0.8,
      modifier_at_end: 1.2
    )

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      modifier = parsed_body["costSlots"].first["modifiers"].first

      assert_kind_of Numeric, modifier["modifierAtStart"]
      assert_kind_of Numeric, modifier["modifierAtEnd"]
      assert_in_delta 0.8, modifier["modifierAtStart"]
      assert_in_delta 1.2, modifier["modifierAtEnd"]
    end
  end

  # The factor alone does not answer "what do I get"; the page multiplies it
  # by the crafted item's own figure for the stat, which the API has to carry.
  test "GET /blueprints/{slug} carries what the factor applies to" do
    shield = create(:component, type_data: {"max_health" => 3168.0})
    @blueprint.build.update!(craftable: shield)
    create(
      :blueprint_cost_modifier,
      slot: @slot,
      property_key: "gpp_shield_maxhealth",
      unit_format: "%+.2f %%"
    )

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      modifier = parsed_body["costSlots"].first["modifiers"].first

      assert_in_delta 3168.0, modifier["baseValue"]
      assert_equal "%", modifier["unit"]
    end
  end

  # 2,060 modifiers move a stat the catalogue holds no figure for, and there
  # the factor is the whole answer rather than a number to multiply.
  test "GET /blueprints/{slug} leaves the base empty for a stat we do not hold" do
    @blueprint.build.update!(craftable: create(:component))
    create(:blueprint_cost_modifier, slot: @slot, property_key: "gpp_weapon_recoil_kick")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      assert_nil parsed_body["costSlots"].first["modifiers"].first["baseValue"]
    end
  end

  # The rate between the two units a recipe and an inventory speak. The slot
  # compares a holding against a cost by converting with it, and treats an
  # absent one as unconvertible -- so a serializer that stopped emitting it
  # would quietly switch every cross-unit comparison back off without failing
  # the schema, which allows null, or the composable tests, which pass their
  # own. A number here is the only thing that catches it.
  test "GET /blueprints/{slug} states what one piece of a counted material takes up" do
    gem = create(:commodity, name: "Hadanite", counted: true, piece_volume: 0.001)
    create(:blueprint_cost_option, slot: @slot, commodity: gem, cost_type: "item")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      material = parsed_body["costSlots"].first["options"].first["commodity"]

      assert_in_delta 0.001, material["pieceVolume"], 0.0000001
      assert_kind_of Numeric, material["pieceVolume"]
    end
  end

  # Bulk is the other half: a crate is sold in seven sizes, so there is no one
  # piece to measure and the slot must not try to convert.
  test "GET /blueprints/{slug} states no piece volume for a bulk material" do
    iron = create(:commodity, name: "Iron", counted: false, piece_volume: nil)
    create(:blueprint_cost_option, slot: @slot, commodity: iron, cost_type: "resource")

    assert_api_response :get, 200, params: {slug: @blueprint.slug} do
      assert_nil parsed_body["costSlots"].first["options"].first.dig("commodity", "pieceVolume")
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
end
