# frozen_string_literal: true

require "openapi_helper"

class Api::V1::EquipmentTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/equipment" do
    get("Equipment list") do
      operationId "equipment"
      tags "Equipment"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Equipment.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::EquipmentQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Equipment::Equipments
      end
    end
  end

  setup do
    @rifle = create(:equipment, name: "P4-AR Rifle", item_type: "assault_rifle")
    @scope = create(:equipment, :attachment, name: "Omarof Scope")
    @magazine = create(:equipment, :magazine, name: "P4-AR Magazine")
  end

  test "GET /equipment lists visible equipment sorted by name" do
    assert_api_response :get, 200 do
      assert_equal ["Omarof Scope", "P4-AR Magazine", "P4-AR Rifle"], parsed_body["items"].map { |i| i["name"] }
    end
  end

  # Skins and NPC loadouts carry their own record but are not something a
  # player holds, so they stay out of the list a picker reads.
  test "GET /equipment leaves out hidden variants" do
    create(:equipment, :hidden, name: "P4-AR Rifle AI")

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  # Gear a later patch stopped shipping keeps its row, so a ledger entry made
  # against it still resolves -- but it should not be offered for a new one.
  test "GET /equipment leaves out gear the current patch no longer ships" do
    create(:equipment, name: "Retired Carbine", version: "0.0.1-live.1")

    assert_api_response :get, 200 do
      assert_not_includes parsed_body["items"].map { |i| i["name"] }, "Retired Carbine"
    end
  end

  test "GET /equipment includes older patches when currentVersion is false" do
    create(:equipment, name: "Retired Carbine", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      assert_includes parsed_body["items"].map { |i| i["name"] }, "Retired Carbine"
    end
  end

  test "GET /equipment filters by equipmentTypeIn" do
    assert_api_response :get, 200, params: {q: {"equipmentTypeIn" => ["weapon_attachment"]}} do
      assert_equal ["Omarof Scope", "P4-AR Magazine"], parsed_body["items"].map { |i| i["name"] }
    end
  end

  test "GET /equipment filters by itemTypeIn" do
    assert_api_response :get, 200, params: {q: {"itemTypeIn" => ["magazine"]}} do
      assert_equal ["P4-AR Magazine"], parsed_body["items"].map { |i| i["name"] }
    end
  end

  test "GET /equipment filters by nameCont" do
    assert_api_response :get, 200, params: {q: {"nameCont" => "Omarof"}} do
      assert_equal ["Omarof Scope"], parsed_body["items"].map { |i| i["name"] }
    end
  end

  test "GET /equipment exposes the armour stats the spec block carries" do
    create(:equipment, :armor, name: "Novikov Exploration Suit")

    assert_api_response :get, 200 do
      suit = parsed_body["items"].find { |i| i["name"] == "Novikov Exploration Suit" }

      assert_equal "torso", suit["slot"]
      assert_equal 25, suit["damageReduction"]
      assert_equal "-225 / 75 °C", suit["temperatureRating"]
      assert_equal "all", suit["backpackCompatibility"]
    end
  end

  test "GET /equipment exposes the fields the picker needs" do
    assert_api_response :get, 200 do
      rifle = parsed_body["items"].find { |i| i["name"] == "P4-AR Rifle" }

      assert_equal @rifle.id, rifle["id"]
      assert_equal "weapon", rifle["equipmentType"]
      assert_equal "assault_rifle", rifle["itemType"]
      assert_equal "2", rifle["size"]
    end
  end
end
