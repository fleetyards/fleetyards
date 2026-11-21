# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryItemsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    post("Create Fleet Inventory Item") do
      operationId "createFleetInventoryItem"
      tags "FleetInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetInventoryItemCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Logistics::FleetInventoryItem
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - member cannot add items") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
  end

  def item_body(overrides = {})
    {name: "Quantanium", category: "commodity", quantity: 250.5, unit: "scu", entryType: "deposit"}.merge(overrides)
  end

  test "POST /inventories/:slug/items creates an item" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body do
      assert_equal "Quantanium", parsed_body["name"]
      assert_in_delta 250.5, parsed_body["quantity"]
    end
  end

  test "POST /inventories/:slug/items can be called by an officer" do
    sign_in @officer

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :post, 403,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: item_body
  end

  test "POST /inventories/:slug/items has the caller carry a deposit by default" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body do
      assert_equal @admin.id, parsed_body.dig("holder", "id")
    end
  end

  test "POST /inventories/:slug/items has the member a deposit is for carry it by default" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body(memberId: @member.id) do
      assert_equal @member.id, parsed_body.dig("holder", "id")
    end
  end

  test "POST /inventories/:slug/items leaves a deposit unassigned when the holder is null" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body(holderId: nil) do
      assert_nil parsed_body["holder"]
    end
  end

  test "POST /inventories/:slug/items refuses a holder outside the fleet" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items",
      params: item_body(holderId: create(:user).id), as: :json

    assert_response :bad_request
  end

  test "POST /inventories/:slug/items withdraws from the named holder" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 100, holder: @member)
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items",
      params: item_body(entryType: "withdrawal", quantity: 40), as: :json

    assert_response :bad_request

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body(entryType: "withdrawal", quantity: 40, holderId: @member.id)
  end

  test "POST /inventories/:slug/items has the caller carry a deposit for a member who left" do
    former = create(:user)
    create(:fleet_membership, fleet: @fleet, user: former, aasm_state: :declined)
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body(memberId: former.id) do
      assert_equal @admin.id, parsed_body.dig("holder", "id")
    end
  end
end
