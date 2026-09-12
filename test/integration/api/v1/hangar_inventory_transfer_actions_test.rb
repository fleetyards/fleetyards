# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryTransferActionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  # Three paths share the PUT verb, and openapi-ruby matches on verb, path
  # params and status -- none of which tell them apart. Every PUT assertion has
  # to name the one it means.
  ACCEPT_PATH = "/hangar/inventory-transfers/{id}/accept"
  DECLINE_PATH = "/hangar/inventory-transfers/{id}/decline"
  CANCEL_PATH = "/hangar/inventory-transfers/{id}/cancel"

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  api_path "/hangar/inventory-transfers/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    get("Hangar Inventory Transfer") do
      operationId "hangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/inventory-transfers/{id}/accept" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Accept Hangar Inventory Transfer") do
      operationId "acceptHangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferAcceptInput

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/inventory-transfers/{id}/decline" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Decline Hangar Inventory Transfer") do
      operationId "declineHangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      produces "application/json"

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/inventory-transfers/{id}/cancel" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    put("Cancel Hangar Inventory Transfer") do
      operationId "cancelHangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      produces "application/json"

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/inventory-transfers/{id}/report" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Transfer id"

    post("Report Hangar Inventory Transfer") do
      operationId "reportHangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferReportInput

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Transfers::InventoryTransfer }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    Flipper.enable("ship_inventories")
    Flipper.enable("inventory_transfers")

    @sender = create(:user)
    @recipient = create(:user)
    @source = create(:inventory, holder: @sender)
    @target = create(:inventory, holder: @recipient)

    entry = create(:inventory_item, inventory: @source,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)

    builder = Inventories::TransferBuilder.new(
      source: @source, actor: @sender, recipient: @recipient,
      lines: [{position_id: entry.position.id, quantity: 40}]
    )
    builder.call
    @transfer = builder.transfer
  end

  test "PUT accept delivers into the inventory the recipient names" do
    sign_in @recipient

    assert_api_response :put, 200, path_params: {id: @transfer.id},
      api_path: ACCEPT_PATH, body: {inventoryId: @target.id} do
      assert_equal "completed", parsed_body["state"]
      assert_equal @target.id, parsed_body["destination"]["id"]
    end

    assert_equal 40, @target.reload.stock_positions.sole.net_quantity
  end

  test "PUT accept into a ship provisions its inventory inside the transaction" do
    vehicle = create(:vehicle, user: @recipient)
    sign_in @recipient

    assert_difference -> { Inventory.count }, 1 do
      assert_api_response :put, 200, path_params: {id: @transfer.id},
        api_path: ACCEPT_PATH, body: {vehicleId: vehicle.id}
    end

    assert_equal 40, vehicle.reload.inventory.stock_positions.sole.net_quantity
  end

  test "PUT accept naming an inventory the acceptor does not hold is a 404" do
    sign_in @recipient

    assert_api_response :put, 404, path_params: {id: @transfer.id},
      api_path: ACCEPT_PATH, body: {inventoryId: @source.id}

    assert @transfer.reload.pending?
  end

  test "PUT accept by somebody else is forbidden" do
    sign_in create(:user)

    assert_api_response :put, 403, path_params: {id: @transfer.id},
      api_path: ACCEPT_PATH, body: {inventoryId: @target.id}
  end

  test "PUT decline sends the goods home" do
    sign_in @recipient

    assert_api_response :put, 200, path_params: {id: @transfer.id}, api_path: DECLINE_PATH do
      assert_equal "declined", parsed_body["state"]
    end

    assert_equal 100, @source.reload.stock_positions.sole.net_quantity
  end

  test "PUT cancel is the sender's move, not the recipient's" do
    sign_in @recipient

    assert_api_response :put, 403, path_params: {id: @transfer.id}, api_path: CANCEL_PATH

    sign_in @sender

    assert_api_response :put, 200, path_params: {id: @transfer.id},
      api_path: CANCEL_PATH do
      assert_equal "cancelled", parsed_body["state"]
    end
  end

  test "PUT on an already answered transfer is a 400" do
    sign_in @recipient
    assert_api_response :put, 200, path_params: {id: @transfer.id},
      api_path: DECLINE_PATH

    assert_api_response :put, 400, path_params: {id: @transfer.id},
      api_path: DECLINE_PATH
  end

  test "POST report declines it, returns the goods and denies the sender" do
    sign_in @recipient

    assert_api_response :post, 200, path_params: {id: @transfer.id}, body: {reason: "spam"} do
      assert_equal "declined", parsed_body["state"]
    end

    assert_equal 100, @source.reload.stock_positions.sole.net_quantity
    assert InventoryTransferRule.between(holder: @recipient, subject: @sender).deny?
    assert_equal 1, InventoryTransferReport.count
  end

  test "POST report twice is a 400" do
    sign_in @recipient
    assert_api_response :post, 200, path_params: {id: @transfer.id}, body: {reason: "spam"}

    assert_api_response :post, 400, path_params: {id: @transfer.id}, body: {reason: "scam"}
  end

  test "GET is readable by both ends and by nobody else" do
    sign_in @sender
    assert_api_response :get, 200, path_params: {id: @transfer.id}

    sign_in @recipient
    assert_api_response :get, 200, path_params: {id: @transfer.id}

    sign_in create(:user)
    assert_api_response :get, 403, path_params: {id: @transfer.id}
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401, path_params: {id: @transfer.id}
  end
end
