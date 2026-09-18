# frozen_string_literal: true

require "openapi_helper"

class Api::V1::BlueprintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/blueprints" do
    get("Blueprints list") do
      operationId "blueprints"
      tags "Blueprints"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Blueprint.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::BlueprintQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Blueprints
      end
    end
  end

  setup do
    @component = create(:component, name: "Bulldog Repeater")
    @blueprint = create(:blueprint, name: "Bulldog Repeater", sc_key: "bp_craft_behr_repeater_s3", craftable: @component)
    @other = create(:blueprint, name: "Omnisky VI Cannon", sc_key: "bp_craft_amrs_lasercannon_s2", craft_time: 960)
  end

  test "GET /blueprints lists the catalogue" do
    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /blueprints filters by nameCont" do
    assert_api_response :get, 200, params: {q: {"nameCont" => "Bulldog"}} do
      items = parsed_body["items"]

      assert_equal 1, items.count
      assert_equal "Bulldog Repeater", items.first["name"]
    end
  end

  test "GET /blueprints filters by what the recipe makes" do
    assert_api_response :get, 200, params: {q: {"craftableTypeEq" => "Component"}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # The reverse of the craftable link. It lives here rather than embedded in
  # each catalogue's detail response because two of the three have none:
  # commodities and equipment are list-only endpoints.
  test "GET /blueprints finds the recipes that make one exact thing" do
    create(:blueprint, craftable: create(:component))

    assert_api_response :get, 200, params: {q: {"craftableIdEq" => @component.id}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /blueprints sorts by craft time" do
    assert_api_response :get, 200, params: {q: {"sorts" => ["craftTime desc"]}} do
      assert_equal "Omnisky VI Cannon", parsed_body["items"].first["name"]
    end
  end

  test "GET /blueprints finds the recipes an org hands out" do
    create(:blueprint_source, build: @blueprint.build, org_name: "Eckhart Security")

    assert_api_response :get, 200, params: {q: {"fromOrg" => "Eckhart Security"}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /blueprints finds the recipes that consume a commodity" do
    commodity = create(:commodity, name: "Iron")
    slot = create(:blueprint_cost_slot, build: @blueprint.build)
    create(:blueprint_cost_option, slot:, commodity:)

    assert_api_response :get, 200, params: {q: {"consumingCommodity" => [commodity.slug]}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # The filter takes a list, so a crafter can ask what any of the materials
  # they are holding is good for.
  test "GET /blueprints finds the recipes consuming any of several commodities" do
    iron = create(:commodity, name: "Iron")
    slot = create(:blueprint_cost_slot, build: @blueprint.build)
    create(:blueprint_cost_option, slot:, commodity: iron)

    other = create(:blueprint)
    corundum = create(:commodity, name: "Corundum")
    other_slot = create(:blueprint_cost_slot, build: other.build)
    create(:blueprint_cost_option, slot: other_slot, commodity: corundum)

    params = {q: {"consumingCommodity" => [iron.slug, corundum.slug]}}

    assert_api_response :get, 200, params: do
      assert_equal [@blueprint.id, other.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /blueprints narrows to the recipes with a stated source" do
    create(:blueprint_source, build: @blueprint.build)

    assert_api_response :get, 200, params: {q: {"withKnownSource" => true}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # Ransack drops a scope whose value is false, so asking for the recipes with
  # *no* stated source through ransack would answer with the whole catalogue --
  # 1,607 rather than 901 against the real tree. The controller applies this
  # one itself, and this is what proves it.
  test "GET /blueprints narrows to the recipes with no stated source" do
    create(:blueprint_source, build: @blueprint.build)

    assert_api_response :get, 200, params: {q: {"withKnownSource" => false}} do
      assert_equal [@other.id], parsed_body["items"].pluck("id")
    end
  end
end
