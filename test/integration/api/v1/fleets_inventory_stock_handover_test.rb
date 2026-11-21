# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryStockHandoverTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock/{slug}/handover" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    post("Hand Over Fleet Inventory Stock") do
      operationId "handOverFleetInventoryStock"
      tags "FleetInventoryStock"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetInventoryHandoverInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::InventoryStockPosition
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @carrier = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@carrier, @member])
    @inventory = create(:fleet_inventory, fleet: @fleet)

    entry = create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other,
      unit: :units, quantity: 5_000, holder: @carrier)

    @path_params = {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: entry.position.slug}
  end

  test "POST handover moves a share to another member" do
    sign_in @admin

    assert_api_response :post, 200, path_params: @path_params,
      body: {fromHolderId: @carrier.id, toHolderId: @member.id, quantity: 2_000, quality: 0} do
      assert_equal 5_000.0, parsed_body["netQuantity"]
      assert_equal [[@carrier.username, 3_000.0], [@member.username, 2_000.0]],
        parsed_body["holders"].map { |share| [share.dig("holder", "username"), share["netQuantity"]] }
    end
  end

  test "POST handover refuses more than the giver holds" do
    sign_in @admin

    assert_api_response :post, 400, path_params: @path_params,
      body: {fromHolderId: @carrier.id, toHolderId: @member.id, quantity: 6_000}
  end

  test "POST handover is refused to a member without inventory write access" do
    sign_in @member

    assert_api_response :post, 403, path_params: @path_params,
      body: {fromHolderId: @carrier.id, toHolderId: @member.id, quantity: 1}
  end

  test "POST handover returns 404 for an unknown position" do
    sign_in @admin

    assert_api_response :post, 404, path_params: @path_params.merge(slug: "nothing--other--units"),
      body: {fromHolderId: @carrier.id, toHolderId: @member.id, quantity: 1}
  end

  test "POST handover returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: @path_params,
      body: {fromHolderId: @carrier.id, toHolderId: @member.id, quantity: 1}
  end
end
