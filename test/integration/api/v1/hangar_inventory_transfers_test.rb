# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryTransfersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventory-transfers" do
    get("Hangar Inventory Transfers") do
      operationId "hangarInventoryTransfers"
      tags "HangarInventoryTransfers"
      produces "application/json"

      parameter name: "direction", in: :query, required: false,
        schema: {type: :string, enum: %w[incoming outgoing]},
        description: "Limit to transfers this user has to answer, or to ones they sent"
      parameter name: "page", in: :query, required: false, schema: {type: :integer}
      parameter name: "limit", in: :query, required: false, schema: {type: :integer}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Transfers::InventoryTransfersList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Create Hangar Inventory Transfer") do
      operationId "createHangarInventoryTransfer"
      tags "HangarInventoryTransfers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryTransferCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "created") do
        schema ::V1::Schemas::Transfers::InventoryTransfer
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
    Flipper.enable("hangar_inventories")
    Flipper.enable("inventory_transfers")

    @user = create(:user)
    @recipient = create(:user)

    @source = create(:inventory, holder: @user)
    @destination = create(:inventory, holder: @user)
    @entry = create(:inventory_item, inventory: @source,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)
  end

  test "POST moves stock between two of my own inventories immediately" do
    sign_in @user

    assert_api_response :post, 201, body: {
      sourceInventoryId: @source.id,
      inventoryId: @destination.id,
      lines: [{positionId: @entry.position.id, quantity: 40}]
    } do
      assert_equal "completed", parsed_body["state"]
      assert parsed_body["immediate"]
      assert_equal 1, parsed_body["lines"].count
      assert_equal 40.0, parsed_body["lines"].first["quantity"]
      assert_equal @destination.id, parsed_body["destination"]["id"]
      assert_nil parsed_body["recipient"]
    end

    assert_equal 60, @source.reload.stock_positions.sole.net_quantity
    assert_equal 40, @destination.reload.stock_positions.sole.net_quantity
  end

  test "POST to another user waits for them and takes the stock now" do
    sign_in @user

    assert_api_response :post, 201, body: {
      sourceInventoryId: @source.id,
      recipientUsername: @recipient.username,
      lines: [{positionId: @entry.position.id, quantity: 40}]
    } do
      assert_equal "pending", parsed_body["state"]
      refute parsed_body["immediate"]
      assert_nil parsed_body["destination"]
      assert_equal "user", parsed_body["recipient"]["kind"]
      assert_equal @recipient.username, parsed_body["recipient"]["name"]
    end

    assert_equal 60, @source.reload.stock_positions.sole.net_quantity
  end

  test "POST is refused when the recipient does not accept transfers" do
    @recipient.update!(inventory_transfer_policy: :nobody)
    sign_in @user

    assert_api_response :post, 400, body: {
      sourceInventoryId: @source.id,
      recipientUsername: @recipient.username,
      lines: [{positionId: @entry.position.id, quantity: 40}]
    }

    assert_equal 100, @source.reload.stock_positions.sole.net_quantity
  end

  test "POST naming an inventory I cannot write to is refused rather than converted into a request" do
    stranger_inventory = create(:inventory, holder: @recipient)
    sign_in @user

    assert_api_response :post, 400, body: {
      sourceInventoryId: @source.id,
      inventoryId: stranger_inventory.id,
      lines: [{positionId: @entry.position.id, quantity: 40}]
    }
  end

  test "POST from an inventory I do not hold is a 404" do
    sign_in @recipient

    assert_api_response :post, 404, body: {
      sourceInventoryId: @source.id,
      inventoryId: @destination.id,
      lines: [{positionId: @entry.position.id, quantity: 1}]
    }
  end

  test "POST requires a signed-in user" do
    assert_api_response :post, 401, body: {
      sourceInventoryId: @source.id,
      lines: [{positionId: @entry.position.id, quantity: 1}]
    }
  end

  test "POST is closed while the feature flag is off" do
    Flipper.disable("inventory_transfers")
    sign_in @user

    assert_api_response :post, 403, body: {
      sourceInventoryId: @source.id,
      inventoryId: @destination.id,
      lines: [{positionId: @entry.position.id, quantity: 1}]
    }
  end

  test "GET lists both directions, and filters to one" do
    create(:inventory_transfer, source_inventory: @source, recipient: @recipient, initiated_by: @user)
    create(:inventory_transfer, source_inventory: create(:inventory, holder: @recipient),
      recipient: @user, initiated_by: @recipient)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end

    assert_api_response :get, 200, params: {direction: "incoming"} do
      assert_equal 1, parsed_body["items"].count
      assert_equal @user.username, parsed_body["items"].first["recipient"]["name"]
    end

    assert_api_response :get, 200, params: {direction: "outgoing"} do
      assert_equal 1, parsed_body["items"].count
      assert_equal @recipient.username, parsed_body["items"].first["recipient"]["name"]
    end
  end

  test "the hangar ledger says which entries a transfer wrote" do
    sign_in @user

    post "/api/v1/hangar/inventory-transfers",
      params: {
        sourceInventoryId: @source.id,
        inventoryId: @destination.id,
        lines: [{positionId: @entry.position.id, quantity: 5}]
      }.to_json,
      headers: {"Content-Type" => "application/json", "Accept" => "application/json"}

    assert_response :created

    get "/api/v1/hangar/inventories/#{@destination.slug}/items",
      headers: {"Accept" => "application/json"}

    assert_response :success

    deposit = response.parsed_body["items"].sole

    assert_not_nil deposit["transferId"]
    assert_not_nil deposit["createdAt"], "a ledger without times has no order"

    # A deposit wants to know where the goods came from.
    assert_equal "in", deposit["transfer"]["direction"]
    assert_equal @source.name, deposit["transfer"]["inventory"]["name"]
    assert_equal @user.username, deposit["transfer"]["counterparty"]["name"]
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401
  end
end
