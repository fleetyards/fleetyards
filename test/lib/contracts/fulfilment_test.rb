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

    test "a late delivery completing an expired contract fulfils it" do
      transfer = pending_transfer
      deposit(transfer, 800)
      @contract.update!(aasm_state: "expired", expired_at: 1.hour.ago)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_contract.fulfilled") { events << 1 }

      transfer.accept!

      @contract.reload
      assert @contract.fulfilled?
      assert_not_nil @contract.fulfilled_at
      assert_not_nil @contract.expired_at
      assert_equal 1, events.size
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end

    test "a late part delivery leaves an expired contract expired, and counts" do
      transfer = pending_transfer
      deposit(transfer, 400)
      @contract.update!(aasm_state: "expired", expired_at: 1.hour.ago)

      transfer.accept!

      @contract.reload
      assert @contract.expired?
      assert_equal 400.to_d, @contract.progress.lines.first.delivered
    end

    test "a cancelled contract is not fulfilled by a late delivery" do
      transfer = pending_transfer
      deposit(transfer, 800)
      @contract.update!(aasm_state: "cancelled", cancelled_at: 1.hour.ago)

      transfer.accept!

      assert @contract.reload.cancelled?
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

    # The crew limit counts rows rather than forbidding a second one, so no index
    # can hold it: two accepts on *different* rows both read the same count and
    # both write.
    #
    # `belongs_to :fleet_contract, touch: true` already serializes the *write*
    # on the contract row, which is why a plain two-thread race passes with the
    # lock removed — and why it is not a guard. The touch blocks after the
    # count, so both accepts still count zero. What discriminates is holding the
    # row while both workers reach their blocking point: without the explicit
    # lock they have already counted and both go through; with it they block
    # before counting, and the second one sees the first.
    test "the crew limit holds when two accepts arrive together" do
      @contract.update!(crew_limit: 1)
      officer = create(:user)

      rows = 2.times.map do
        create(:fleet_contract_assignment, fleet_contract: @contract, user: create(:user))
      end

      workers = nil

      @contract.with_lock do
        workers = rows.map do |row|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              FleetContractAssignment.find(row.id).approve!(officer)
            end
          rescue => e
            e
          end
        end

        # Long enough for both to reach whatever they block on, which is the
        # count in the unlocked version and the row itself in the locked one.
        sleep 0.5
      end

      workers.each { |worker| worker.join(5) }

      assert_equal 1, @contract.fleet_contract_assignments.accepted.crew.count,
        "the crew went over its limit"
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
