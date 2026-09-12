# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetInventoryTransfersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventory-transfers" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Inventory Transfers") do
      operationId "fleetInventoryTransfers"
      tags "FleetInventoryTransfers"
      produces "application/json"

      parameter name: "direction", in: :query, required: false,
        schema: {type: :string, enum: %w[incoming outgoing]},
        description: "Limit to transfers this fleet has to answer, or to ones it sent"
      parameter name: "page", in: :query, required: false, schema: {type: :integer}
      parameter name: "limit", in: :query, required: false, schema: {type: :integer}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfersList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Fleet Inventory Transfer") do
      operationId "createFleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "created") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/inventory-transfers/{id}/accept" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Accept Fleet Inventory Transfer") do
      operationId "acceptFleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferAcceptInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    Flipper.enable("fleet_logistics")
    Flipper.enable("inventory_transfers")

    @fleet = create(:fleet)
    @officer = create(:user)
    create(:fleet_membership, :accepted, :as_officer, fleet: @fleet, user: @officer)
    @member = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: @member)

    @depot = create(:fleet_inventory, fleet: @fleet)
    @entry = create(:fleet_inventory_item, fleet_inventory: @depot,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)

    @outsider = create(:user)
  end

  test "POST issues stock from a fleet to a user, who then accepts it" do
    sign_in @officer

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      recipientUsername: @outsider.username,
      lines: [{positionId: @entry.position.id, quantity: 25}]
    } do
      assert_equal "pending", parsed_body["state"]
      assert_equal "fleet", parsed_body["sender"]["kind"]
      assert_equal @fleet.name, parsed_body["sender"]["name"]
      assert_equal "user", parsed_body["recipient"]["kind"]
    end

    assert_equal 75, @depot.reload.stock_positions.sole.net_quantity
  end

  test "a member without the inventory privilege cannot send" do
    sign_in @member

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      recipientUsername: @outsider.username,
      lines: [{positionId: @entry.position.id, quantity: 25}]
    }

    assert_equal 100, @depot.reload.stock_positions.sole.net_quantity
  end

  # A fleet a caller cannot see is a 404 rather than a 403, matching every other
  # fleet-scoped endpoint -- the visibility scope runs before the policy.
  test "a non-member cannot even see the fleet's transfers" do
    sign_in @outsider

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end

  test "PUT accept lands a donation in the fleet inventory the officer names" do
    donor = create(:user)
    donor_inventory = create(:inventory, holder: donor)
    donation = create(:inventory_item, inventory: donor_inventory,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 50)

    builder = Inventories::TransferBuilder.new(
      source: donor_inventory, actor: donor, recipient: @fleet,
      lines: [{position_id: donation.position.id, quantity: 20}]
    )

    assert builder.call, builder.errors.full_messages.to_sentence

    sign_in @officer

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, id: builder.transfer.id},
      body: {fleetInventoryId: @depot.id} do
      assert_equal "completed", parsed_body["state"]
      assert_equal "fleet", parsed_body["destination"]["kind"]
    end

    deposit = @depot.fleet_inventory_items.find_by(name: "Titanium")

    assert_equal 20, deposit.quantity
    assert_equal @officer.id, deposit.added_by
  end

  test "GET lists the fleet's own transfers, both directions" do
    create(:inventory_transfer, source_inventory: nil, source_fleet_inventory: @depot,
      recipient: @outsider, initiated_by: @officer)
    create(:inventory_transfer, recipient_fleet: @fleet, initiated_by: @outsider,
      source_inventory: create(:inventory, holder: @outsider))

    sign_in @officer

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body["items"].count
    end

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {direction: "incoming"} do
      assert_equal 1, parsed_body["items"].count
      assert_equal @fleet.name, parsed_body["items"].first["recipient"]["name"]
    end
  end

  test "the fleet logistics flag still gates this" do
    Flipper.disable("fleet_logistics")
    sign_in @officer

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
