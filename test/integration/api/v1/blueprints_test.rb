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
  # each catalogue's detail response, so all three catalogues ask it the same
  # way.
  test "GET /blueprints finds the recipes that make one exact thing" do
    create(:blueprint, craftable: create(:component))

    assert_api_response :get, 200, params: {q: {"craftableIdEq" => @component.id}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # A hidden variant has no public page, so the recipe row must not link to one.
  test "GET /blueprints says whether what a recipe makes has a page" do
    skin = create(:equipment, :hidden, name: "P4-AR Boneyard")
    create(:blueprint, name: "P4-AR Boneyard", craftable: skin)

    assert_api_response :get, 200, params: {q: {"craftableIdEq" => skin.id}} do
      assert_equal false, parsed_body["items"].first.dig("craftable", "listed")
    end

    assert_api_response :get, 200, params: {q: {"craftableIdEq" => @component.id}} do
      assert_equal true, parsed_body["items"].first.dig("craftable", "listed")
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

  # On the row, not only on the detail page: a crafter scanning the list has to
  # be able to see which side of the law a recipe is reachable from.
  test "GET /blueprints says which sides of the law hand each recipe out" do
    create(:blueprint_source, build: @blueprint.build, alignment: "outlaw", position: 1)
    create(:blueprint_source, build: @blueprint.build, alignment: "lawful", position: 2)

    assert_api_response :get, 200 do
      items = parsed_body["items"].index_by { |item| item["id"] }

      assert_equal ["lawful", "outlaw"], items[@blueprint.id]["sourceAlignments"]
      assert_empty items[@other.id]["sourceAlignments"]
    end
  end

  test "GET /blueprints finds the recipes one side of the law hands out" do
    create(:blueprint_source, build: @blueprint.build, alignment: "outlaw")
    create(:blueprint_source, build: @other.build, alignment: "lawful")

    assert_api_response :get, 200, params: {q: {"sourceAlignmentIn" => ["outlaw"]}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # Both sides hand out the same pool often enough that picking two has to mean
  # "reachable either way".
  test "GET /blueprints takes several alignments as a union" do
    create(:blueprint_source, build: @blueprint.build, alignment: "outlaw")
    create(:blueprint_source, build: @other.build, alignment: "neutral")
    lawful = create(:blueprint)
    create(:blueprint_source, build: lawful.build, alignment: "lawful")

    params = {q: {"sourceAlignmentIn" => ["outlaw", "neutral"]}}

    assert_api_response :get, 200, params: do
      assert_equal [@blueprint.id, @other.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /blueprints finds the recipes that consume a commodity" do
    commodity = create(:commodity, name: "Iron")
    slot = create(:blueprint_cost_slot, build: @blueprint.build)
    create(:blueprint_cost_option, slot:, commodity:)

    assert_api_response :get, 200, params: {q: {"consumingCommodityIn" => [commodity.slug]}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # The filter shipped taking a single slug and the schema published that, so
  # the string form has to keep working.
  test "GET /blueprints finds the recipes that consume a commodity named alone" do
    commodity = create(:commodity, name: "Iron")
    slot = create(:blueprint_cost_slot, build: @blueprint.build)
    create(:blueprint_cost_option, slot:, commodity:)

    assert_api_response :get, 200, params: {q: {"consumingCommodity" => commodity.slug}} do
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

    params = {q: {"consumingCommodityIn" => [iron.slug, corundum.slug]}}

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

  test "GET /blueprints says which recipes the reader holds" do
    user = create(:user)
    create(:user_blueprint, user:, blueprint: @blueprint)
    sign_in user

    assert_api_response :get, 200 do
      owned = parsed_body["items"].to_h { |item| [item["id"], item["owned"]] }

      assert owned[@blueprint.id]
      assert_not owned[@other.id]
    end
  end

  # The catalogue is public and its payload is fragment cached on the
  # blueprint, its build and the source -- no reader in the key. `owned` is
  # rendered outside that block for exactly this reason, and a second reader
  # getting the first one's answer is what it would look like if it moved back
  # in.
  test "GET /blueprints does not serve one reader's marks to the next" do
    holder = create(:user)
    create(:user_blueprint, user: holder, blueprint: @blueprint)

    sign_in holder
    assert_api_response :get, 200 do
      assert parsed_body["items"].find { |item| item["id"] == @blueprint.id }["owned"]
    end
    sign_out holder

    assert_api_response :get, 200 do
      assert_not parsed_body["items"].find { |item| item["id"] == @blueprint.id }["owned"]
    end
  end

  test "GET /blueprints narrows to the recipes the reader holds" do
    user = create(:user)
    create(:user_blueprint, user:, blueprint: @blueprint)
    sign_in user

    assert_api_response :get, 200, params: {q: {"owned" => true}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("id")
    end
  end

  # The same trap `withKnownSource` documents: ransack skips a scope whose
  # value is false, so this asked through ransack would answer "the ones I do
  # not have" with the whole catalogue.
  test "GET /blueprints narrows to the recipes the reader does not hold" do
    user = create(:user)
    create(:user_blueprint, user:, blueprint: @blueprint)
    sign_in user

    assert_api_response :get, 200, params: {q: {"owned" => false}} do
      assert_equal [@other.id], parsed_body["items"].pluck("id")
    end
  end

  # Nobody holds anything signed out, so "mine" is empty and "not mine" is the
  # catalogue -- rather than either of them being an error.
  test "GET /blueprints answers the owned filter for an anonymous reader" do
    assert_api_response :get, 200, params: {q: {"owned" => true}} do
      assert_empty parsed_body["items"]
    end

    assert_api_response :get, 200, params: {q: {"owned" => false}} do
      assert_equal 2, parsed_body["items"].count
    end
  end
end
