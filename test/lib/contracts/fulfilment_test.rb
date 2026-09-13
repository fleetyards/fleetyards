# frozen_string_literal: true

require "test_helper"

module Contracts
  class FulfilmentTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @destination = create(:fleet_inventory, fleet: @fleet)
      @contractor = create(:user)
      @contract = create(:fleet_contract, :in_progress,
        fleet: @fleet, destination_fleet_inventory: @destination)
      @contract.fleet_contract_items.destroy_all
      create(:fleet_contract_item, fleet_contract: @contract,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)
      create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @contractor)
    end

    test "completing the last delivery fulfils the contract" do
      transfer = pending_transfer
      deposit(transfer, 800)

      transfer.accept!

      assert @contract.reload.fulfilled?
      assert_not_nil @contract.fulfilled_at
    end

    test "a part delivery leaves the contract running" do
      transfer = pending_transfer
      deposit(transfer, 400)

      transfer.accept!

      assert @contract.reload.in_progress?
    end

    test "a contract that is not in progress is left alone" do
      @contract.update!(aasm_state: "open")
      transfer = pending_transfer
      deposit(transfer, 800)

      transfer.accept!

      assert @contract.reload.open?
    end

    test "fulfilling announces itself once" do
      transfer = pending_transfer
      deposit(transfer, 800)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_contract.fulfilled") { events << 1 }

      transfer.accept!
      Fulfilment.new(@contract.reload).call

      assert_equal 1, events.size
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end

    private def pending_transfer
      create(:inventory_transfer,
        fleet_contract: @contract,
        initiated_by: @contractor,
        source_inventory: create(:inventory, holder: @contractor),
        source_fleet_inventory: nil,
        destination_fleet_inventory: @destination)
    end

    private def deposit(transfer, quantity)
      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu,
        quantity: quantity)
    end
  end

  # `whiny_transitions: false` lets a losing transition return false *after* its
  # writes, so without the lock two final deliveries landing at once both read an
  # unfulfilled contract and both transition it.
  class FulfilmentConcurrencyTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    setup do
      # Nothing rolls back here, so what this test creates has to be found again
      # to be removed. The factories reach further than the ids this test holds
      # -- a contract brings a `created_by`, a fleet inventory brings a fleet --
      # and users left behind collide with later tests, because the user factory
      # draws its email from Faker's finite name pool.
      @known_user_ids = User.pluck(:id)
      @known_fleet_ids = Fleet.pluck(:id)

      @fleet = create(:fleet)
      @destination = create(:fleet_inventory, fleet: @fleet)
      @contractor = create(:user)
      @contract = create(:fleet_contract, :in_progress,
        fleet: @fleet, destination_fleet_inventory: @destination)
      @contract.fleet_contract_items.destroy_all
      create(:fleet_contract_item, fleet_contract: @contract,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)
      create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @contractor)
    end

    teardown do
      FleetInventoryItem.delete_all
      FleetInventoryPosition.delete_all
      InventoryTransfer.delete_all
      InventoryItem.delete_all
      InventoryPosition.delete_all
      Inventory.delete_all
      FleetContractAssignment.delete_all
      FleetContractItem.delete_all
      FleetContract.delete_all
      FleetInventory.delete_all
      Fleet.where.not(id: @known_fleet_ids).destroy_all
      User.where.not(id: @known_user_ids).destroy_all
    end

    test "two final deliveries fulfil the contract once" do
      2.times { |index| deposit(400, index) }

      outcomes = race(2) { Fulfilment.new(FleetContract.find(@contract.id)).call }

      assert_equal 1, outcomes.count(true), "both checks reported a fulfilment"
      assert FleetContract.find(@contract.id).fulfilled?
    end

    private def deposit(quantity, index)
      transfer = create(:inventory_transfer,
        fleet_contract: @contract,
        aasm_state: "completed",
        initiated_by: @contractor,
        source_inventory: create(:inventory, holder: @contractor, name: "Hold #{index}"),
        source_fleet_inventory: nil,
        destination_fleet_inventory: @destination)

      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu,
        quantity: quantity)
    end

    private def race(count)
      gate = Queue.new
      threads = Array.new(count) do |index|
        Thread.new do
          gate.pop
          ActiveRecord::Base.connection_pool.with_connection { yield(index) }
        rescue => e
          e
        end
      end

      count.times { gate << :go }
      threads.map(&:value)
    end
  end
end
