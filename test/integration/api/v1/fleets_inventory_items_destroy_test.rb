# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInventoryItemsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    delete("Delete Fleet Inventory Item") do
      operationId "destroyFleetInventoryItem"
      tags "FleetInventoryItems"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - member cannot delete items") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
    @item = create(:fleet_inventory_item, fleet_inventory: @inventory)
  end

  test "DELETE /inventories/:slug/items/:id deletes the item" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id}
  end

  test "DELETE /inventories/:slug/items/:id returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id}
  end

  test "DELETE /inventories/:slug/items/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id}
  end

  test "DELETE /inventories/:slug/items/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
