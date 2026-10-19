# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsFromPledgeItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items/from-pledge-items" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    post("Add Hangar Pledge Items to an Inventory") do
      operationId "addPledgeItemsToHangarInventory"
      tags "HangarInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::AddPledgeItemsToInventoryInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::AddPledgeItemsToInventoryResult
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
    @inventory = create(:inventory, holder: @user)
  end

  test "deposits each ship component and piece of gear once, referring to its catalogue item" do
    cooler = create(:component, name: "BriskAir IC-20", category: "cooler")
    cannon = create(:component, name: "M3A Cannon", category: "weapons")
    rifle = create(:equipment, name: "P4-AR Rifle")
    parts = [
      create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20", quantity: 2,
        catalogue_component: cooler),
      create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "M3A Cannon", catalogue_component: cannon),
      create(:hangar_pledge_item, user: @user, kind: "equipment", name: "P4-AR Rifle", catalogue_equipment: rifle),
      create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "J-Span Cryo-Star Cooler")
    ]
    sign_in @user

    assert_api_response :post, 200, path_params: {hangarInventorySlug: @inventory.slug},
      body: {pledgeItemIds: parts.map(&:id)} do
      assert_equal parts.map(&:id).sort, parsed_body["addedPledgeItemIds"].sort
      assert_empty parsed_body["skippedPledgeItemIds"]
    end

    entries = @inventory.inventory_items.index_by(&:name)
    assert_equal ["component", 2, cooler], entries["BriskAir IC-20"].then { [it.category, it.quantity.to_i, it.item] }
    assert_equal "weapon", entries["M3A Cannon"].category
    assert_equal ["equipment", rifle], entries["P4-AR Rifle"].then { [it.category, it.item] }
    assert_nil entries["J-Span Cryo-Star Cooler"].item
    assert(parts.all? { it.reload.inventory_item.present? })
  end

  test "skips an item already added, so the stock is never doubled" do
    part = create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20")
    sign_in @user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items", params: {pledgeItemIds: [part.id]}, as: :json
    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items", params: {pledgeItemIds: [part.id]}, as: :json

    assert_response :ok
    assert_equal [part.id], response.parsed_body["skippedPledgeItemIds"]
    assert_equal 1, @inventory.inventory_items.count
  end

  test "ignores paints, other users' items and anything not to keep in an inventory" do
    paint = create(:hangar_pledge_item, user: @user, kind: "paint", name: "Cutlass - Akuma Paint")
    foreign = create(:hangar_pledge_item, kind: "ship_component", name: "Sovereign IP-10")
    sign_in @user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items",
      params: {pledgeItemIds: [paint.id, foreign.id]}, as: :json

    assert_response :ok
    assert_empty response.parsed_body["addedPledgeItemIds"]
    assert_empty @inventory.inventory_items
  end

  test "adds nothing to somebody else's inventory" do
    part = create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20")
    sign_in @user

    assert_api_response :post, 404, path_params: {hangarInventorySlug: create(:inventory).slug},
      body: {pledgeItemIds: [part.id]}

    assert_nil part.reload.inventory_item
  end

  test "requires a session or token" do
    assert_api_response :post, 401, path_params: {hangarInventorySlug: @inventory.slug}, body: {pledgeItemIds: []}
  end
end
