# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    post("Create Hangar Inventory Item") do
      operationId "createHangarInventoryItem"
      tags "HangarInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarInventoryItemCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Hangar::Logistics::HangarInventoryItem
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:inventory, holder: @user)
  end

  def item_body(overrides = {})
    {name: "Quantanium", category: "commodity", quantity: 250.5, unit: "scu", entryType: "deposit"}.merge(overrides)
  end

  test "POST /hangar/inventories/:slug/items creates a deposit" do
    sign_in @user

    assert_api_response :post, 201,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body do
      assert_equal "Quantanium", parsed_body["name"]
      assert_equal "deposit", parsed_body["entryType"]
      assert_in_delta 250.5, parsed_body["quantity"]
    end
  end

  test "POST /hangar/inventories/:slug/items records a crafted part" do
    component = create(:component, name: "Bulwark")
    blueprint = create(:blueprint, craftable: component)
    slot = create(:blueprint_cost_slot, build: blueprint.build, position: 1)
    create(:blueprint_cost_modifier, slot:)

    sign_in @user

    assert_api_response :post, 201,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body(
        name: "Bulwark", category: "component", unit: "units", quantity: 1,
        itemType: "Component", itemId: component.id,
        craftedBlueprintId: blueprint.id, craftedQualities: {"1" => 820}
      ) do
      assert_equal blueprint.slug, parsed_body.dig("crafted", "blueprint", "slug")
      assert_equal({"1" => 820}, parsed_body.dig("crafted", "qualities"))
    end
  end

  test "POST /hangar/inventories/:slug/items refuses a crafted part missing a slot's grade" do
    component = create(:component, name: "Bulwark")
    blueprint = create(:blueprint, craftable: component)
    slot = create(:blueprint_cost_slot, build: blueprint.build, position: 1)
    create(:blueprint_cost_modifier, slot:)

    sign_in @user

    assert_api_response :post, 400,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body(
        name: "Bulwark", category: "component", unit: "units", quantity: 1,
        itemType: "Component", itemId: component.id,
        craftedBlueprintId: blueprint.id, craftedQualities: {}
      )
  end

  test "POST /hangar/inventories/:slug/items returns 400 for a zero quantity" do
    sign_in @user

    assert_api_response :post, 400,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body(quantity: 0)
  end

  test "POST /hangar/inventories/:slug/items returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :post, 404,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /hangar/inventories/:slug/items returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /hangar/inventories/:slug/items with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {hangarInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: item_body
  end
end
