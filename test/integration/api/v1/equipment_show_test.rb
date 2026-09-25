# frozen_string_literal: true

require "openapi_helper"

class Api::V1::EquipmentShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/equipment/{slug}" do
    get("Equipment detail") do
      operationId "equipmentItem"
      tags "Equipment"
      produces "application/json"

      parameter name: :slug, in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Equipment
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @rifle = create(:equipment, name: "P4-AR Rifle", sc_key: "behr_rifle_ballistic_01")
  end

  test "GET /equipment/{slug} returns the item" do
    assert_api_response :get, 200, params: {slug: @rifle.slug} do
      assert_equal "P4-AR Rifle", parsed_body["name"]
      assert_equal "p4-ar-rifle", parsed_body["slug"]
      assert_equal false, parsed_body["retired"]
    end
  end

  test "GET /equipment/{slug} labels the facts it carries in the caller's locale" do
    suit = create(:equipment, :armor, name: "Novikov Exploration Suit", sub_type: "LightArmor")

    assert_api_response :get, 200, params: {slug: suit.slug} do
      assert_equal "Armor", parsed_body["equipmentTypeLabel"]
      assert_equal "Heavy Utility", parsed_body["itemTypeLabel"]
      assert_equal "Light Armor", parsed_body["subTypeLabel"]
      assert_equal "Torso", parsed_body["slotLabel"]
      assert_nil parsed_body["weaponClassLabel"]
    end
  end

  # A patch that drops an item leaves its row, and a bookmark or a ledger entry
  # still points at it -- so the page stays and says so.
  test "GET /equipment/{slug} still answers for an item the build dropped" do
    retired = create(:equipment, name: "Retired Carbine", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {slug: retired.slug} do
      assert_equal true, parsed_body["retired"]
    end
  end

  # The list leaves hidden variants out, so a page for one would be reachable
  # only by guessing its URL.
  test "GET /equipment/{slug} 404s for a hidden variant" do
    hidden = create(:equipment, :hidden, name: "P4-AR Rifle AI")

    assert_api_response :get, 404, params: {slug: hidden.slug}
  end

  test "GET /equipment/{slug} 404s for a slug nobody has" do
    assert_api_response :get, 404, params: {slug: "no-such-equipment-slug"}
  end
end
