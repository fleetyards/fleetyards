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
      parameter name: "q", in: :query, required: false,
        schema: ::V1::Schemas::Queries::InventoryTransferQuery,
        description: "Filters"
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

  # An immediate transfer names no recipient, so one delivered into my own
  # inventory matched neither scope: it showed on the sender's list and was
  # invisible to the person who received it.
  test "GET incoming shows what was delivered here, not only what was addressed to me" do
    fleet = create(:fleet)
    create(:fleet_membership, :accepted, :as_officer, fleet:, user: @user)
    Flipper.enable("fleet_logistics")

    depot = create(:fleet_inventory, fleet:)
    entry = create(:fleet_inventory_item, fleet_inventory: depot,
      name: "Agricium", category: :commodity, unit: :scu, quantity: 20)

    builder = Inventories::TransferBuilder.new(
      source: depot, actor: @user, destination: @destination,
      lines: [{position_id: entry.position.id, quantity: 5}]
    )

    assert builder.call, builder.errors.full_messages.to_sentence
    assert builder.transfer.completed?
    assert_nil builder.transfer.recipient, "an immediate transfer names no recipient"

    sign_in @user

    assert_api_response :get, 200, params: {direction: "incoming"} do
      assert_equal [builder.transfer.id], parsed_body["items"].map { |t| t["id"] }
    end
  end

  test "GET filters by state" do
    create(:inventory_transfer, source_inventory: @source, recipient: @recipient, initiated_by: @user)
    create(:inventory_transfer, :completed, source_inventory: @source,
      recipient: @recipient, initiated_by: @user)

    sign_in @user

    assert_api_response :get, 200, params: {direction: "outgoing", q: {stateEq: "pending"}} do
      assert_equal ["pending"], parsed_body["items"].map { |t| t["state"] }.uniq
    end

    assert_api_response :get, 200, params: {direction: "outgoing", q: {stateEq: "completed"}} do
      assert_equal ["completed"], parsed_body["items"].map { |t| t["state"] }.uniq
    end
  end

  # An array permitted as a scalar is dropped outright, so the caller gets the
  # whole unfiltered list back rather than an error.
  test "GET filters by several states at once" do
    create(:inventory_transfer, source_inventory: @source, recipient: @recipient, initiated_by: @user)
    create(:inventory_transfer, :completed, source_inventory: @source,
      recipient: @recipient, initiated_by: @user)
    create(:inventory_transfer, source_inventory: @source, recipient: @recipient,
      initiated_by: @user, aasm_state: "declined")

    sign_in @user

    assert_api_response :get, 200,
      params: {direction: "outgoing", q: {stateIn: %w[pending completed]}} do
      assert_equal %w[completed pending], parsed_body["items"].map { |t| t["state"] }.uniq.sort
    end
  end

  # The whole point of the contract link: a delivery is an ordinary transfer,
  # and the contract's progress is a sum over what it deposited. Addressed to
  # the fleet rather than to the depot directly -- from this mount a member
  # names a party, and the fleet says where it lands.
  test "a delivery filed under a contract counts once the fleet accepts it" do
    contract, depot = contract_for(@user)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientFleetSlug: contract.fleet.slug,
             contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]} do
      assert_equal "pending", parsed_body["state"]
    end

    transfer = InventoryTransfer.find(parsed_body["id"])

    assert_equal contract.id, transfer.fleet_contract_id
    assert_equal 0.to_d, Contracts::Progress.new(contract).lines.first.delivered

    # The accept path itself is covered on the fleet mount; what is being
    # asserted here is that the deposit it writes is what moves the contract.
    Inventories::TransferResolver.new(transfer, actor: @user).accept(depot)

    assert_equal 40.to_d, Contracts::Progress.new(contract.reload).lines.first.delivered
  end

  test "a delivery the fleet lands somewhere else counts for nothing" do
    contract, _depot = contract_for(@user)
    elsewhere = create(:fleet_inventory, fleet: contract.fleet)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientFleetSlug: contract.fleet.slug,
             contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}

    transfer = InventoryTransfer.find(parsed_body["id"])
    Inventories::TransferResolver.new(transfer, actor: @user).accept(elsewhere)

    assert_equal 0.to_d, Contracts::Progress.new(contract.reload).lines.first.delivered
  end

  # Attribution is certain only while the source still exists, so the link
  # writes it down there and then.
  test "a contract delivery records who its goods came from" do
    contract, _depot = contract_for(@user)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientFleetSlug: contract.fleet.slug,
             contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}

    transfer = InventoryTransfer.find(parsed_body["id"])

    assert_equal @user.id, transfer.fleet_contract_contributor_id
  end

  test "a transfer with no contract records no contributor" do
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientUsername: @recipient.username,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}

    assert_nil InventoryTransfer.find(parsed_body["id"]).fleet_contract_contributor_id
  end

  test "POST naming a contract from a fleet the caller is not in is refused" do
    outsiders_fleet = create(:fleet)
    depot = create(:fleet_inventory, fleet: outsiders_fleet)
    contract = create(:fleet_contract, :in_progress, fleet: outsiders_fleet,
      destination_fleet_inventory: depot)

    sign_in @user

    assert_api_response :post, 400,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientUsername: @recipient.username,
             contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  test "POST naming a contract that is not being worked yet is refused" do
    contract, _depot = contract_for(@user, state: :published)
    sign_in @user

    assert_api_response :post, 400,
      path_params: {},
      body: {sourceInventoryId: @source.id, recipientFleetSlug: contract.fleet.slug,
             contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  test "POST to a contract's hangar destination waits for the author" do
    contract, author, locker = hangar_contract_for(@user)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, inventoryId: locker.id, contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]} do
      assert_equal "pending", parsed_body["state"]
      assert_nil parsed_body["destination"]
      assert_equal "user", parsed_body["recipient"]["kind"]
      assert_equal author.username, parsed_body["recipient"]["name"]
    end

    transfer = InventoryTransfer.find(parsed_body["id"])

    assert_equal author, transfer.recipient
    assert_nil transfer.destination
  end

  # Naming the inventory as the contract's destination is the author asking
  # for the goods, so a closed stance does not refuse them.
  test "POST to a contract's hangar destination reaches an author who takes no transfers" do
    contract, author, locker = hangar_contract_for(@user)
    author.update!(inventory_transfer_policy: :nobody)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {},
      body: {sourceInventoryId: @source.id, inventoryId: locker.id, contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  test "POST to a contract's hangar destination is refused to a member not working it" do
    contract, _author, locker = hangar_contract_for(@recipient)
    create(:fleet_membership, fleet: contract.fleet, user: @user, aasm_state: :accepted,
      fleet_role: contract.fleet.fleet_roles.ranked.last)
    sign_in @user

    assert_no_difference -> { InventoryTransfer.count } do
      assert_api_response :post, 400,
        path_params: {},
        body: {sourceInventoryId: @source.id, inventoryId: locker.id, contractId: contract.id,
               lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
    end

    assert_equal 100, @source.reload.stock_positions.sole.net_quantity
  end

  test "POST to a hangar destination of a contract nobody is working yet is refused" do
    contract, _author, locker = hangar_contract_for(@user, state: :published)
    sign_in @user

    assert_api_response :post, 400,
      path_params: {},
      body: {sourceInventoryId: @source.id, inventoryId: locker.id, contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  # The contract opens exactly one of the author's inventories to its
  # contractors, and only as a target.
  test "POST to another of the author's inventories under the contract is refused" do
    contract, author, _locker = hangar_contract_for(@user)
    other = create(:inventory, holder: author)
    sign_in @user

    assert_api_response :post, 400,
      path_params: {},
      body: {sourceInventoryId: @source.id, inventoryId: other.id, contractId: contract.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  test "POST to a contract's hangar destination without naming the contract is refused" do
    _contract, _author, locker = hangar_contract_for(@user)
    sign_in @user

    assert_api_response :post, 400,
      path_params: {},
      body: {sourceInventoryId: @source.id, inventoryId: locker.id,
             lines: [{positionId: @entry.reload.position_id, quantity: 40}]}
  end

  private def hangar_contract_for(worker, state: :in_progress)
    author = create(:user)
    fleet = create(:fleet, members: [author, worker])
    Flipper.enable("fleet_contracts")

    contract = create(:fleet_contract, state, :hangar_destination, fleet: fleet, created_by: author)
    contract.fleet_contract_items.destroy_all
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 800)

    if state == :in_progress
      contract.fleet_contract_assignments.create!(user: worker, role: :lead,
        aasm_state: "accepted", accepted_at: Time.current)
    end

    [contract, author, contract.destination_inventory]
  end

  private def contract_for(worker, state: :in_progress)
    fleet = create(:fleet, admins: [worker])
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")

    depot = create(:fleet_inventory, fleet: fleet)
    contract = create(:fleet_contract, state, fleet: fleet, destination_fleet_inventory: depot)
    contract.fleet_contract_items.destroy_all
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 800)

    if state == :in_progress
      contract.fleet_contract_assignments.create!(user: worker, role: :lead,
        aasm_state: "accepted", accepted_at: Time.current)
    end

    [contract, depot]
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401
  end
end
