# frozen_string_literal: true

require "test_helper"

class FleetContractTest < ActiveSupport::TestCase
  test "a transport contract needs a source inventory and the others must not have one" do
    fleet = create(:fleet)

    transport = build(:fleet_contract, :transport, fleet: fleet)
    assert transport.valid?

    transport.source_fleet_inventory = nil
    assert_not transport.valid?

    procurement = build(:fleet_contract, fleet: fleet,
      source_fleet_inventory: create(:fleet_inventory, fleet: fleet))
    assert_not procurement.valid?
  end

  test "both inventories have to belong to the posting fleet" do
    contract = build(:fleet_contract, destination_fleet_inventory: create(:fleet_inventory))

    assert_not contract.valid?
    assert_includes contract.errors.details[:base].map { |error| error[:error] }, :inventory_not_in_fleet
  end

  test "a contract cannot haul to the inventory it hauls from" do
    fleet = create(:fleet)
    inventory = create(:fleet_inventory, fleet: fleet)

    contract = build(:fleet_contract, :transport, fleet: fleet,
      source_fleet_inventory: inventory, destination_fleet_inventory: inventory)

    assert_not contract.valid?
  end

  test "publishing needs something to deliver" do
    contract = create(:fleet_contract)

    assert_not contract.publish!
    assert contract.draft?

    create(:fleet_contract_item, fleet_contract: contract)

    assert contract.reload.publish!
    assert contract.open?
    assert_not_nil contract.published_at
  end

  test "claiming and releasing move the contract and stamp it" do
    contract = create(:fleet_contract, :published)

    assert contract.claim!
    assert contract.in_progress?
    assert_not_nil contract.claimed_at

    assert contract.release!
    assert contract.open?
    assert_nil contract.claimed_at
  end

  test "the database refuses a second accepted lead" do
    contract = create(:fleet_contract, :in_progress)
    create(:fleet_contract_assignment, :lead, fleet_contract: contract)

    assert_raises ActiveRecord::RecordNotUnique do
      FleetContractAssignment.insert_all!(
        [{
          fleet_contract_id: contract.id, user_id: create(:user).id,
          role: 0, aasm_state: "accepted",
          created_at: Time.current, updated_at: Time.current
        }]
      )
    end
  end

  test "a released lead does not block the next claim" do
    contract = create(:fleet_contract, :in_progress)
    lead = create(:fleet_contract_assignment, :lead, fleet_contract: contract)

    lead.withdraw!

    assert_nothing_raised do
      create(:fleet_contract_assignment, :lead, fleet_contract: contract)
    end
  end

  test "the crew limit is counted over the other accepted rows" do
    contract = create(:fleet_contract, :in_progress, crew_limit: 1)
    create(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    second = build(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    assert_not second.valid?
    assert_not contract.accepting_crew?
  end

  test "an accepted crew member may be saved again without tripping its own limit" do
    contract = create(:fleet_contract, :in_progress, crew_limit: 1)
    assignment = create(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    assert assignment.update(approved_by: create(:user))
  end
end
