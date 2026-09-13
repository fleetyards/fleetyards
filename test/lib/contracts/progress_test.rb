# frozen_string_literal: true

require "test_helper"

module Contracts
  class ProgressTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @destination = create(:fleet_inventory, fleet: @fleet)
      @contractor = create(:user)
      @contract = create(:fleet_contract, :in_progress,
        fleet: @fleet, destination_fleet_inventory: @destination)
      @contract.fleet_contract_items.destroy_all
      @item = create(:fleet_contract_item, fleet_contract: @contract,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)
      create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @contractor)
    end

    test "a delivery through a linked transfer counts" do
      deliver(quantity: 240)

      line = progress.lines.first

      assert_equal 240.to_d, line.delivered
      assert_equal 560.to_d, line.remaining
      assert_not line.complete?
    end

    test "a deposit with no transfer counts for nothing" do
      create(:fleet_inventory_item, fleet_inventory: @destination,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

      assert_equal 0.to_d, progress.lines.first.delivered
    end

    test "a deposit into another inventory counts for nothing" do
      other = create(:fleet_inventory, fleet: @fleet)
      transfer = linked_transfer(destination: other)
      create(:fleet_inventory_item, fleet_inventory: other, inventory_transfer: transfer,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

      assert_equal 0.to_d, progress.lines.first.delivered
    end

    test "a declined transfer leaves nothing at the destination to count" do
      transfer = linked_transfer(state: "declined")
      # A refusal compensates back into the source, so the destination ledger
      # never sees the goods at all -- this asserts the absence directly.
      assert_empty @destination.fleet_inventory_items.where(inventory_transfer: transfer)
      assert_equal 0.to_d, progress.lines.first.delivered
    end

    test "the name is matched case-insensitively" do
      deliver(quantity: 100, name: "titanium")

      assert_equal 100.to_d, progress.lines.first.delivered
    end

    test "a different unit is a different position" do
      deliver(quantity: 100, category: :component, unit: :units)

      assert_equal 0.to_d, progress.lines.first.delivered
    end

    test "a crafting line ignores deposits under its required quality" do
      @contract.update!(kind: :crafting, source_fleet_inventory: nil)
      @item.update!(min_quality: 500)

      deliver(quantity: 100, quality: 400)
      deliver(quantity: 300, quality: 500)
      deliver(quantity: 200, quality: 900)

      assert_equal 500.to_d, progress.lines.first.delivered
    end

    test "a line with no threshold counts every grade" do
      deliver(quantity: 100, quality: 0)
      deliver(quantity: 100, quality: 900)

      assert_equal 200.to_d, progress.lines.first.delivered
    end

    test "pickup and delivery are kept apart on a transport contract" do
      source = create(:fleet_inventory, fleet: @fleet)
      @contract.update!(kind: :transport, source_fleet_inventory: source)

      # The withdrawal is checked against live stock, so the depot has to be
      # holding the goods before the courier can take them out of it.
      create(:fleet_inventory_item, fleet_inventory: source, entry_type: :deposit,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

      pickup = linked_transfer(source: source, destination: nil, recipient: @contractor)
      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: pickup,
        entry_type: :withdrawal, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)

      deliver(quantity: 150)

      line = progress.lines.first

      assert_equal 400.to_d, line.picked_up
      assert_equal 150.to_d, line.delivered
    end

    # A refused pickup keeps its withdrawal and compensates back into the
    # source, so counting withdrawals alone reports goods as still being in a
    # courier's hold after they came home.
    test "a returned pickup stops counting as picked up" do
      source = create(:fleet_inventory, fleet: @fleet)
      @contract.update!(kind: :transport, source_fleet_inventory: source)

      create(:fleet_inventory_item, fleet_inventory: source, entry_type: :deposit,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

      pickup = linked_transfer(source: source, destination: nil, recipient: @contractor,
        state: "declined")

      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: pickup,
        entry_type: :withdrawal, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)

      assert_equal 400.to_d, progress.lines.first.picked_up

      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: pickup,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)

      assert_equal 0.to_d, progress.lines.first.picked_up
    end

    test "a partly returned pickup counts only what stayed out" do
      source = create(:fleet_inventory, fleet: @fleet)
      @contract.update!(kind: :transport, source_fleet_inventory: source)

      create(:fleet_inventory_item, fleet_inventory: source, entry_type: :deposit,
        name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

      pickup = linked_transfer(source: source, destination: nil, recipient: @contractor)
      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: pickup,
        entry_type: :withdrawal, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)
      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: pickup,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu, quantity: 150)

      assert_equal 250.to_d, progress.lines.first.picked_up
    end

    # The weights divide money, so a deleted inventory must not move a share
    # onto whoever happened to press the button.
    test "a deleted source credits nobody rather than the officer who dispatched it" do
      officer = create(:user)
      transfer = linked_transfer(initiated_by: officer)

      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)

      assert_equal [@contractor.id], progress.lines.first.contributions.map(&:user_id)

      # Straight to the column: nulling the source is what `ON DELETE SET NULL`
      # does, and the model would refuse a transfer with no source at all.
      transfer.update_columns(source_inventory_id: nil)

      assert_empty progress.lines.first.contributions
    end

    test "a deleted source still credits a contractor who dispatched their own goods" do
      transfer = linked_transfer(initiated_by: @contractor)

      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: "Titanium", category: :commodity, unit: :scu, quantity: 400)

      transfer.update_columns(source_inventory_id: nil)

      assert_equal [@contractor.id], progress.lines.first.contributions.map(&:user_id)
    end

    test "two contractors are attributed separately and their weights sum to one" do
      second = create(:user)
      create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: second)

      deliver(quantity: 600)
      deliver(quantity: 200, user: second)

      contributions = progress.lines.first.contributions.index_by(&:user_id)

      assert_equal 600.to_d, contributions[@contractor.id].delivered
      assert_equal 200.to_d, contributions[second.id].delivered
      assert_in_delta 0.75, contributions[@contractor.id].weight.to_f, 0.0001
      assert_in_delta 0.25, contributions[second.id].weight.to_f, 0.0001
      assert_in_delta 1.0, progress.total_weight.to_f, 0.0001
    end

    test "over-delivering does not make a line worth more than it asked for" do
      deliver(quantity: 1600)

      line = progress.lines.first

      assert line.complete?
      assert_in_delta 1.0, line.fraction.to_f, 0.0001
      assert_in_delta 1.0, progress.total_weight.to_f, 0.0001
    end

    test "goods are attributed to whoever held them, not to whoever pressed the button" do
      officer = create(:user)
      deliver(quantity: 100, initiated_by: officer)

      assert_equal [@contractor.id], progress.lines.first.contributions.map(&:user_id)
    end

    test "a contract is complete only when every line is" do
      second = create(:fleet_contract_item, fleet_contract: @contract,
        name: "Quantanium", category: :commodity, unit: :scu, quantity: 200)

      deliver(quantity: 800)

      assert_not progress.complete?
      assert_in_delta 0.5, progress.fraction.to_f, 0.0001

      deliver(quantity: 200, name: second.name)

      assert progress.complete?
      assert_in_delta 1.0, progress.fraction.to_f, 0.0001
    end

    private def progress
      Contracts::Progress.new(@contract.reload)
    end

    private def deliver(quantity:, name: "Titanium", category: :commodity, unit: :scu,
      quality: nil, user: @contractor, initiated_by: nil)
      transfer = linked_transfer(user: user, initiated_by: initiated_by || user)

      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: name, category: category, unit: unit,
        quantity: quantity, quality: quality)
    end

    private def linked_transfer(user: @contractor, source: nil, destination: :default,
      recipient: nil, initiated_by: nil, state: "completed")
      attributes = {
        fleet_contract: @contract,
        initiated_by: initiated_by || user,
        aasm_state: state,
        source_inventory: nil,
        source_fleet_inventory: nil
      }

      if source.is_a?(::FleetInventory)
        attributes[:source_fleet_inventory] = source
      else
        attributes[:source_inventory] = source || create(:inventory, holder: user)
      end

      attributes[:destination_fleet_inventory] = (destination == :default) ? @destination : destination
      attributes[:recipient] = recipient
      attributes[:expires_at] = 14.days.from_now if recipient.present?

      create(:inventory_transfer, **attributes)
    end
  end
end
