# frozen_string_literal: true

require "openapi_helper"

# A contract whose author cannot accept deliveries into the fleet's
# inventories, worked from posting to fulfilment through the API.
class Api::V1::FleetContractHangarDeliveryTest < ActionDispatch::IntegrationTest
  setup do
    %w[fleet_contracts fleet_logistics inventory_transfers hangar_inventories].each { |flag| Flipper.enable(flag) }

    @author = create(:user)
    @contractor = create(:user)
    @fleet = create(:fleet, members: [@contractor])
    create(:fleet_membership, fleet: @fleet, user: @author, aasm_state: :accepted,
      fleet_role: create(:fleet_role, fleet: @fleet, name: "Quartermaster",
        resource_access: FleetRole.preset_privileges[:member] + ["fleet:contracts:create", "fleet:contracts:update"]))

    @locker = create(:inventory, holder: @author, name: "Locker")
    @hold = create(:inventory, holder: @contractor, name: "Hold")
    @entry = create(:inventory_item, inventory: @hold,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 1000)
  end

  test "an author without inventory rights receives a delivery into their own hangar" do
    sign_in @author

    post "/api/v1/fleets/#{@fleet.slug}/contracts", as: :json, params: {
      kind: "procurement", destinationInventoryId: @locker.id,
      items: [{name: "Titanium", category: "commodity", unit: "scu", quantity: "800.0"}]
    }

    assert_response :created
    slug = response.parsed_body["slug"]

    put "/api/v1/fleets/#{@fleet.slug}/contracts/#{slug}/publish", as: :json

    assert_response :success

    contract = FleetContract.find_by!(slug:)

    sign_in @contractor

    put "/api/v1/fleets/#{@fleet.slug}/contracts/#{slug}/claim", as: :json

    assert_response :success

    get "/api/v1/hangar/contract-destinations", as: :json

    assert_response :success
    assert_equal [@locker.id], response.parsed_body.map { |target| target["destination"]["id"] }

    # Only a target: the contract does not open the inventory to them.
    get "/api/v1/hangar/inventories/#{@locker.slug}", as: :json

    assert_response :not_found

    post "/api/v1/hangar/inventory-transfers", as: :json, params: {
      sourceInventoryId: @hold.id, inventoryId: @locker.id, contractId: contract.id,
      lines: [{positionId: @entry.position.id, quantity: 800}]
    }

    assert_response :created
    transfer_id = response.parsed_body["id"]

    assert_equal "pending", response.parsed_body["state"]
    assert_equal @author.username, response.parsed_body["recipient"]["name"]
    assert_equal 0.to_d, contract.reload.progress.lines.first.delivered

    sign_in @author

    put "/api/v1/hangar/inventory-transfers/#{transfer_id}/accept", as: :json,
      params: {inventoryId: @locker.id}

    assert_response :success
    assert_equal "completed", response.parsed_body["state"]

    contract.reload

    assert_equal 800.to_d, Contracts::Progress.new(contract).lines.first.delivered
    assert_predicate contract, :fulfilled?
    assert_equal 800, @locker.reload.stock_positions.sole.net_quantity
  end

  # Flags are per person. The author's hangar is judged by the author's flag,
  # not by the contractor's: a contractor who only runs ship holds can still
  # deliver into it.
  test "a delivery into the author's hangar is judged by the author's hangar flag" do
    Flipper.disable(:hangar_inventories)
    Flipper.enable_actor(:hangar_inventories, @author)
    Flipper.enable_actor(:ship_inventories, @contractor)

    ship_hold = Inventory.provision_for(create(:vehicle, user: @contractor), holder: @contractor)
    cargo = create(:inventory_item, inventory: ship_hold,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 100)

    contract = create(:fleet_contract, :in_progress, fleet: @fleet, created_by: @author,
      destination_fleet_inventory: nil, destination_inventory: @locker)
    create(:fleet_contract_assignment, :accepted, fleet_contract: contract, user: @contractor)

    sign_in @contractor

    post "/api/v1/hangar/inventory-transfers", as: :json, params: {
      sourceInventoryId: ship_hold.id, inventoryId: @locker.id, contractId: contract.id,
      lines: [{positionId: cargo.position.id, quantity: 100}]
    }

    assert_response :created
    assert_equal @author.username, response.parsed_body["recipient"]["name"]
  end
end
