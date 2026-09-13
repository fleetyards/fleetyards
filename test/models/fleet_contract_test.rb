# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_contracts
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("draft"), not null
#  cancelled_at                   :datetime
#  claimed_at                     :datetime
#  crew_limit                     :integer
#  deadline                       :datetime
#  description                    :text
#  expired_at                     :datetime
#  fulfilled_at                   :datetime
#  kind                           :integer          default(0), not null
#  published_at                   :datetime
#  reimburse_expenses             :boolean          default(TRUE), not null
#  reward                         :decimal(15, 2)   default(0.0), not null
#  slug                           :string           not null
#  title                          :string           not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  created_by_id                  :uuid
#  destination_fleet_inventory_id :uuid
#  fleet_id                       :uuid             not null
#  source_fleet_inventory_id      :uuid
#
# Indexes
#
#  index_fleet_contracts_on_created_by_id                   (created_by_id)
#  index_fleet_contracts_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_fleet_contracts_on_fleet_id                        (fleet_id)
#  index_fleet_contracts_on_fleet_id_and_aasm_state         (fleet_id,aasm_state)
#  index_fleet_contracts_on_fleet_id_and_kind               (fleet_id,kind)
#  index_fleet_contracts_on_fleet_id_and_slug               (fleet_id,slug) UNIQUE
#  index_fleet_contracts_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#
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

  # Two lines with the same identity would both match the same deposits, so one
  # delivery would satisfy both.
  test "a contract cannot ask for the same position twice" do
    contract = create(:fleet_contract)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 100)

    twin = build(:fleet_contract_item, fleet_contract: contract,
      name: "titanium", category: :commodity, unit: :scu, quantity: 50)

    assert_not twin.valid?
    assert_includes twin.errors.details[:name].map { |error| error[:error] }, :taken
  end

  test "the database refuses a duplicate identity that slips past the validation" do
    contract = create(:fleet_contract)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 100)

    assert_raises ActiveRecord::RecordNotUnique do
      FleetContractItem.insert_all!(
        [{
          fleet_contract_id: contract.id, name: "TITANIUM",
          category: 0, unit: 0, quantity: 5, position: 9,
          created_at: Time.current, updated_at: Time.current
        }]
      )
    end
  end

  test "the same position in another contract is fine" do
    create(:fleet_contract_item, name: "Titanium", category: :commodity, unit: :scu)

    assert build(:fleet_contract_item, name: "Titanium", category: :commodity, unit: :scu).valid?
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
