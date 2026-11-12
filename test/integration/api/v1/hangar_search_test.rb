# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSearchTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/search" do
    get("Search the current user's hangar") do
      operationId "hangarSearch"
      tags "Search"
      produces "application/json"

      parameter name: "q", in: :query, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::SearchResults
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @other = create(:user)
  end

  def groups
    parsed_body["groups"].to_h { |group| [group["type"], group["items"].pluck("name")] }
  end

  test "GET /hangar/search refuses a visitor" do
    assert_api_response :get, 401, params: {q: "omni"}
  end

  test "GET /hangar/search finds a user's own things, one group per list" do
    model = create(:model, name: "Omni Hauler")
    create(:vehicle, user: @user, model:)
    create(:vehicle, :wanted, user: @user, model: create(:model, name: "Omni Scout"))
    create(:user_blueprint, user: @user, blueprint: create(:blueprint, name: "Omni Rifle"))
    create(:inventory_item, inventory: create(:inventory, holder: @user, name: "Depot"), name: "Omni Ore")
    create(:hangar_pledge_item, user: @user, kind: "paint", name: "Omni Paint")
    create(:buyback_pledge, user: @user, name: "Omni Pack")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_equal(
        {
          "HangarVehicle" => ["Omni Hauler"],
          "WishlistVehicle" => ["Omni Scout"],
          "OwnedBlueprint" => ["Omni Rifle"],
          "InventoryItem" => ["Omni Ore"],
          "Paint" => ["Omni Paint"],
          "Buyback" => ["Omni Pack"]
        },
        groups
      )
    end
  end

  test "GET /hangar/search never returns another user's things" do
    create(:vehicle, user: @other, model: create(:model, name: "Omni Hauler"))
    create(:vehicle, :wanted, user: @other, model: create(:model, name: "Omni Scout"))
    create(:user_blueprint, user: @other, blueprint: create(:blueprint, name: "Omni Rifle"))
    create(:inventory_item, inventory: create(:inventory, holder: @other), name: "Omni Ore")
    create(:hangar_pledge_item, user: @other, name: "Omni Paint")
    create(:buyback_pledge, user: @other, name: "Omni Pack")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_empty parsed_body["groups"]
    end
  end

  test "GET /hangar/search leaves out what the hangar list hides" do
    model = create(:model, name: "Omni Hauler")
    create(:vehicle, :loaner, user: @user, model:)
    create(:vehicle, user: @user, model:, hidden_by_user: true)
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_empty parsed_body["groups"]
    end
  end

  test "GET /hangar/search finds accepted friends only" do
    create(:friendship, :accepted, requester: @user, addressee: create(:user, username: "omnifriend"))
    create(:friendship, requester: @user, addressee: create(:user, username: "omnipending"))
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_equal({"Friend" => ["omnifriend"]}, groups)
      assert_equal "User", parsed_body["groups"].first["items"].first["type"]
    end
  end

  test "GET /hangar/search shows a friend who hides their presence as offline" do
    hidden = create(:user, username: "omnihidden", show_online_status: false)
    shown = create(:user, username: "omnishown")
    create(:friendship, :accepted, requester: @user, addressee: hidden)
    create(:friendship, :accepted, requester: @user, addressee: shown)
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      items = parsed_body["groups"].first["items"].index_by { |item| item["name"] }

      assert_equal false, items["omnihidden"]["online"]
      assert_equal false, items["omnishown"]["online"]
    end
  end

  test "GET /hangar/search shows a hangar token no friends without the friends list's scopes" do
    create(:friendship, :accepted, requester: @user, addressee: create(:user, username: "omnifriend"))
    create(:vehicle, user: @user, model: create(:model, name: "Omni Hauler"))
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["hangar:read"])

    assert_api_response :get, 200, params: {q: "omni"}, headers: {"Authorization" => "Bearer #{token.token}"} do
      assert_equal({"HangarVehicle" => ["Omni Hauler"]}, groups)
    end
  end

  test "GET /hangar/search shows friends to a token carrying the friends list's scopes" do
    create(:friendship, :accepted, requester: @user, addressee: create(:user, username: "omnifriend"))
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["hangar:read", "public"])

    assert_api_response :get, 200, params: {q: "omni"}, headers: {"Authorization" => "Bearer #{token.token}"} do
      assert_equal({"Friend" => ["omnifriend"]}, groups)
    end
  end

  test "GET /hangar/search shows a user's ships, items and pledges by their pictures" do
    png = Rails.root.join("test/fixtures/files/test.png")
    model = create(:model, name: "Omni Hauler")
    model.angled_view.attach(io: png.open, filename: "angled.png", content_type: "image/png")
    create(:vehicle, user: @user, model:)
    component = create(:component, :with_store_image, name: "Omni Cannon")
    create(:inventory_item, inventory: create(:inventory, holder: @user), name: "Omni Cannon", item: component)
    create(:hangar_pledge_item, user: @user, kind: "paint", name: "Omni Paint", image_url: "https://example.test/paint.jpg")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      items = parsed_body["groups"].to_h { |group| [group["type"], group["items"].first] }

      assert items["HangarVehicle"]["image"].present?
      assert items["InventoryItem"]["image"].present?
      assert_equal "https://example.test/paint.jpg", items["Paint"]["imageUrl"]
    end
  end

  test "GET /hangar/search shows a ship by its angled render over the owner's own picture" do
    png = Rails.root.join("test/fixtures/files/test.png")
    model = create(:model, name: "Omni Hauler")
    model.angled_view.attach(io: png.open, filename: "angled.png", content_type: "image/png")
    vehicle = create(:vehicle, user: @user, model:)
    vehicle.image.attach(io: png.open, filename: "own.png", content_type: "image/png")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      image = parsed_body["groups"].find { |group| group["type"] == "HangarVehicle" }["items"].first["image"]

      assert_equal "angled.png", image["name"]
    end
  end

  test "GET /hangar/search says when a list has more than it offers" do
    6.times { |n| create(:hangar_pledge_item, user: @user, kind: "paint", name: "Omni Paint #{n}") }
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      group = parsed_body["groups"].first

      assert_equal 5, group["items"].size
      assert_equal true, group["hasMore"]
    end
  end
end
