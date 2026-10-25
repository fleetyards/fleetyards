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
    helmet = create(:equipment, name: "Morningstar Helmet", equipment_type: "armor", item_type: "heavy_armor", slot: "helmet")
    parts = [
      create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20", quantity: 2,
        catalogue_component: cooler),
      create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "M3A Cannon", catalogue_component: cannon),
      create(:hangar_pledge_item, user: @user, kind: "equipment", name: "P4-AR Rifle", catalogue_equipment: rifle),
      create(:hangar_pledge_item, user: @user, kind: "equipment", name: "Morningstar Helmet", catalogue_equipment: helmet),
      create(:hangar_pledge_item, user: @user, kind: "equipment", name: "Unmatched Jacket"),
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
    assert_equal ["weapon", rifle], entries["P4-AR Rifle"].then { [it.category, it.item] }
    assert_equal ["armor", helmet], entries["Morningstar Helmet"].then { [it.category, it.item] }
    assert_equal "equipment", entries["Unmatched Jacket"].category
    assert_nil entries["J-Span Cryo-Star Cooler"].item
    assert_equal parts.map(&:source_key).sort, @inventory.inventory_items.pluck(:source_pledge_item_key).sort
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

  # A cleared hangar synced again recreates the row, not the pledge.
  test "skips an item whose deposit came from the same pledge item before it was recreated" do
    part = create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20",
      rsi_pledge_id: "123")
    sign_in @user
    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items", params: {pledgeItemIds: [part.id]}, as: :json
    part.destroy!
    again = create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "BriskAir IC-20",
      rsi_pledge_id: "123")

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items", params: {pledgeItemIds: [again.id]}, as: :json

    assert_equal [again.id], response.parsed_body["skippedPledgeItemIds"]
    assert_equal 1, @inventory.inventory_items.count
  end

  # The catalogue's name, so it joins the position of the same part entered by hand.
  test "names a matched part's deposit as the catalogue does" do
    repeater = create(:component, name: "CF-117 Bulldog Repeater", category: "weapons")
    part = create(:hangar_pledge_item, user: @user, kind: "ship_component", name: "CF-117 Bulldog (S1)",
      catalogue_component: repeater)
    sign_in @user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/from-pledge-items", params: {pledgeItemIds: [part.id]}, as: :json

    assert_equal ["CF-117 Bulldog Repeater", "weapon"], @inventory.inventory_items.sole.then { [it.name, it.category] }
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

    assert_empty InventoryItem.where(source_pledge_item_key: part.source_key)
  end

  test "requires a session or token" do
    assert_api_response :post, 401, path_params: {hangarInventorySlug: @inventory.slug}, body: {pledgeItemIds: []}
  end
end
