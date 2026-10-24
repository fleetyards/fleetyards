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

  # A load writes the build and leaves the row alone when no fact on it changed,
  # so the row alone cannot key the fragment.
  test "GET /equipment/{slug} picks up a build a load wrote after it was cached" do
    dropped = create(:equipment, name: "Old Rifle", version: "0.0.1-live.1")

    with_fragment_caching do
      assert_api_response :get, 200, params: {slug: dropped.slug} do
        assert parsed_body["retired"]
      end

      travel 1.second do
        create(:equipment_build, equipment: dropped, name: "New Rifle")
      end

      assert_api_response :get, 200, params: {slug: dropped.slug} do
        assert_not parsed_body["retired"]
        assert_equal "New Rifle", parsed_body["name"]
      end
    end
  end

  test "GET /equipment/{slug} labels the facts it carries in the caller's locale" do
    suit = create(:equipment, :armor, name: "Novikov Exploration Suit", sub_type: "LightArmor")

    assert_api_response :get, 200, params: {slug: suit.slug} do
      assert_equal "Armor", parsed_body["equipmentTypeLabel"]
      assert_equal "Heavy Utility", parsed_body["itemTypeLabel"]
      assert_equal "Light Armor", parsed_body["subTypeLabel"]
      assert_equal "Torso", parsed_body["slotLabel"]
      assert_equal "All", parsed_body["backpackCompatibilityLabel"]
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

  test "GET /equipment/{slug} carries the views and the holo" do
    @rifle.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")
    @rifle.holo.attach(io: StringIO.new("glTF"), filename: "holo.glb", content_type: "model/gltf-binary")

    assert_api_response :get, 200, params: {slug: @rifle.slug} do
      assert_equal "angled.png", parsed_body.dig("media", "angledView", "name")
      assert_equal "holo.glb", parsed_body.dig("media", "holo", "name")
    end
  end

  test "GET /equipment/{slug} shows equipment without a store image by its angled view" do
    @rifle.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")

    assert_api_response :get, 200, params: {slug: @rifle.slug} do
      assert_equal "angled.png", parsed_body.dig("storeImage", "name")
      assert_equal "angled.png", parsed_body.dig("media", "storeImage", "name")
    end
  end

  test "GET /equipment/{slug} carries the store image in media too" do
    @rifle.store_image.attach(io: file_fixture("test.png").open, filename: "store.png", content_type: "image/png")
    @rifle.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")

    assert_api_response :get, 200, params: {slug: @rifle.slug} do
      assert_equal "store.png", parsed_body.dig("storeImage", "name")
      assert_equal "store.png", parsed_body.dig("media", "storeImage", "name")
    end
  end

  test "GET /equipment/{slug} 404s for a slug nobody has" do
    assert_api_response :get, 404, params: {slug: "no-such-equipment-slug"}
  end
end
