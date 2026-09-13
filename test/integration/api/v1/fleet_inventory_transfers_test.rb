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

  FLEET_WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:write"]},
    {OpenId: ["fleet", "fleet:write"]}
  ].freeze

  # Three of these share the PUT verb, so every PUT assertion names the one it
  # means -- openapi-ruby matches on verb, path params and status.
  ACCEPT_PATH = "/fleets/{fleetSlug}/inventory-transfers/{id}/accept"
  DECLINE_PATH = "/fleets/{fleetSlug}/inventory-transfers/{id}/decline"
  CANCEL_PATH = "/fleets/{fleetSlug}/inventory-transfers/{id}/cancel"

  api_path "/fleets/{fleetSlug}/inventory-transfers/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    get("Fleet Inventory Transfer") do
      operationId "fleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/inventory-transfers/{id}/decline" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Decline Fleet Inventory Transfer") do
      operationId "declineFleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      produces "application/json"

      security FLEET_WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/inventory-transfers/{id}/cancel" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Cancel Fleet Inventory Transfer") do
      operationId "cancelFleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      produces "application/json"

      security FLEET_WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/inventory-transfers/{id}/report" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    post("Report Fleet Inventory Transfer") do
      operationId "reportFleetInventoryTransfer"
      tags "FleetInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferReportInput

      security FLEET_WRITE_SECURITY

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
      api_path: ACCEPT_PATH, body: {fleetInventoryId: @depot.id} do
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

  test "an officer declines a transfer addressed to the fleet, and the goods go home" do
    transfer = donation_to_fleet

    sign_in @officer

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, id: transfer.id},
      api_path: DECLINE_PATH do
      assert_equal "declined", parsed_body["state"]
    end

    assert_equal 50, transfer.source.reload.stock_positions.sole.net_quantity
  end

  test "an officer cancels a transfer the fleet sent" do
    sign_in @officer

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      recipientUsername: @outsider.username,
      lines: [{positionId: @entry.position.id, quantity: 25}]
    }

    transfer = InventoryTransfer.sole

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, id: transfer.id},
      api_path: CANCEL_PATH do
      assert_equal "cancelled", parsed_body["state"]
    end

    assert_equal 100, @depot.reload.stock_positions.sole.net_quantity
  end

  test "reporting on the fleet's behalf files the rule against the fleet" do
    transfer = donation_to_fleet

    sign_in @officer

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, id: transfer.id},
      body: {reason: "spam"} do
      assert_equal "declined", parsed_body["state"]
    end

    assert InventoryTransferRule.between(holder: @fleet, subject: transfer.sender_party).deny?
  end

  test "GET one is readable by the fleet it is addressed to" do
    transfer = donation_to_fleet

    sign_in @officer
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, id: transfer.id}

    sign_in @member
    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug, id: transfer.id}
  end

  # The sixth movement: a fleet issuing kit to one of its members, where the
  # member is the one pressing the button. Immediate, because an officer who may
  # withdraw from the fleet and deposit into their own hangar could already have
  # done both by hand.
  test "an officer moves fleet stock into their own hangar inventory" do
    Flipper.enable("inventory_transfers")
    locker = create(:inventory, holder: @officer)

    sign_in @officer

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      inventoryId: locker.id,
      lines: [{positionId: @entry.position.id, quantity: 10}]
    } do
      assert_equal "completed", parsed_body["state"]
      assert_equal "user", parsed_body["destination"]["kind"]
    end

    assert_equal 10, locker.reload.stock_positions.sole.net_quantity
    assert_equal 90, @depot.reload.stock_positions.sole.net_quantity
  end

  test "a member cannot pull fleet stock into their own hangar" do
    locker = create(:inventory, holder: @member)

    sign_in @member

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      inventoryId: locker.id,
      lines: [{positionId: @entry.position.id, quantity: 10}]
    }

    assert_equal 100, @depot.reload.stock_positions.sole.net_quantity
  end

  # Sending the same amount again and again, the way a person would: each one
  # has to come out of the fleet, and the fleet has to run out.
  test "repeated sends to my own inventory deplete the fleet" do
    Flipper.enable("inventory_transfers")
    locker = create(:inventory, holder: @officer)

    sign_in @officer

    2.times do
      assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {
        sourceInventoryId: @depot.id,
        inventoryId: locker.id,
        lines: [{positionId: @entry.position.id, quantity: 40}]
      }
    end

    assert_equal 20, @depot.reload.stock_positions.sole.net_quantity
    assert_equal 80, locker.reload.stock_positions.sole.net_quantity

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {
      sourceInventoryId: @depot.id,
      inventoryId: locker.id,
      lines: [{positionId: @entry.position.id, quantity: 40}]
    }

    assert_equal 20, @depot.reload.stock_positions.sole.net_quantity
    assert_equal 80, locker.reload.stock_positions.sole.net_quantity
  end

  private def donation_to_fleet
    donor = create(:user)
    donor_inventory = create(:inventory, holder: donor)
    donation = create(:inventory_item, inventory: donor_inventory,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 50)

    builder = Inventories::TransferBuilder.new(
      source: donor_inventory, actor: donor, recipient: @fleet,
      lines: [{position_id: donation.position.id, quantity: 20}]
    )

    assert builder.call, builder.errors.full_messages.to_sentence

    builder.transfer
  end
end
