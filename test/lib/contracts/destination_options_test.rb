# frozen_string_literal: true

require "test_helper"

module Contracts
  class DestinationOptionsTest < ActiveSupport::TestCase
    setup do
      Flipper.enable(:inventory_transfers)
      Flipper.enable(:hangar_inventories)
      Flipper.enable(:fleet_logistics)

      @officer = create(:user)
      @author = create(:user)
      @fleet = create(:fleet, officers: [@officer])
      create(:fleet_membership, fleet: @fleet, user: @author, aasm_state: :accepted,
        fleet_role: create(:fleet_role, fleet: @fleet, name: "Quartermaster",
          resource_access: FleetRole.preset_privileges[:member] + ["fleet:contracts:create"]))

      @depot = create(:fleet_inventory, fleet: @fleet, name: "Depot")
      @vault = create(:fleet_inventory, fleet: @fleet, name: "Vault", visibility: :officers_only)
      @locker = create(:inventory, holder: @author, name: "Locker")
    end

    test "an author without inventory rights is offered only their own inventories" do
      options = DestinationOptions.new(fleet: @fleet, editor: @author)

      assert_empty options.fleet_inventories
      assert_equal [@locker], options.hangar_inventories
      assert options.allows?(@locker)
      assert_not options.allows?(@depot)
    end

    test "an officer is offered the fleet inventories they can write to, and their own" do
      own = create(:inventory, holder: @officer)
      options = DestinationOptions.new(fleet: @fleet, editor: @officer)

      assert_equal [@depot, @vault], options.fleet_inventories
      assert_equal [own], options.hangar_inventories
      assert options.allows?(own)
    end

    test "an officers-only inventory is not offered to someone who may only update" do
      updater = create(:user)
      create(:fleet_membership, fleet: @fleet, user: updater, aasm_state: :accepted,
        fleet_role: create(:fleet_role, fleet: @fleet, name: "Clerk",
          resource_access: FleetRole.preset_privileges[:member] + ["fleet:inventories:update"]))

      assert_equal [@depot], DestinationOptions.new(fleet: @fleet, editor: updater).fleet_inventories
    end

    test "somebody else's inventory is never allowed" do
      options = DestinationOptions.new(fleet: @fleet, editor: @officer)

      assert_not options.allows?(@locker)
    end

    test "another editor cannot choose the author's inventory for them" do
      options = DestinationOptions.new(fleet: @fleet, editor: @officer, author: @author)

      assert_empty options.hangar_inventories
      assert_not options.allows?(@locker)
    end

    test "no hangar inventory is offered to an author who cannot receive transfers" do
      Flipper.disable(:inventory_transfers)

      assert_empty DestinationOptions.new(fleet: @fleet, editor: @author).hangar_inventories
    end

    test "no fleet inventory is offered while the fleet's logistics are off" do
      Flipper.disable(:fleet_logistics)

      assert_empty DestinationOptions.new(fleet: @fleet, editor: @officer).fleet_inventories
    end

    test "a ship's hold is offered only while ship inventories are on" do
      hold = Inventory.provision_for(create(:vehicle, user: @author), holder: @author)

      assert_not_includes DestinationOptions.new(fleet: @fleet, editor: @author).hangar_inventories, hold

      Flipper.enable(:ship_inventories)

      assert_includes DestinationOptions.new(fleet: @fleet, editor: @author).hangar_inventories, hold
    end

    # A delivery into any of them is addressed to the author, and the gate
    # refuses a person as recipient without the hangar flag -- a ship's hold
    # included.
    test "nothing is offered while the gate would refuse the author as recipient" do
      Inventory.provision_for(create(:vehicle, user: @author), holder: @author)
      Flipper.disable(:hangar_inventories)
      Flipper.enable(:ship_inventories)

      assert_equal :unavailable, ::Inventories::TransferGate.new(sender: @officer, recipient: @author).refusal&.code
      assert_empty DestinationOptions.new(fleet: @fleet, editor: @author).hangar_inventories
    end

    test "a contract refuses a destination its editor may not choose" do
      contract = build(:fleet_contract, fleet: @fleet, created_by: @author,
        destination_fleet_inventory: @depot)
      contract.destination_chosen_by = @author

      assert_not contract.valid?
      assert_includes contract.errors.details[:destination_fleet_inventory].pluck(:error), :not_selectable

      contract.destination_fleet_inventory = nil
      contract.destination_inventory = @locker

      assert_predicate contract, :valid?
    end

    test "an unchanged destination is not re-checked" do
      contract = create(:fleet_contract, fleet: @fleet, created_by: @author, destination_fleet_inventory: @depot)
      contract.destination_chosen_by = @author

      assert contract.update(description: "Still going to the depot")
    end
  end
end
