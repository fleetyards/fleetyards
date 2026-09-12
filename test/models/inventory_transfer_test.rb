# frozen_string_literal: true

require "test_helper"

class InventoryTransferTest < ActiveSupport::TestCase
  test "needs exactly one source" do
    transfer = build(:inventory_transfer, :to_user, source_fleet_inventory: build(:fleet_inventory))

    refute transfer.valid?
    assert_includes transfer.errors.full_messages, "needs exactly one source inventory"
  end

  test "needs a target" do
    transfer = build(:inventory_transfer)

    refute transfer.valid?
    assert_includes transfer.errors.full_messages, "needs a destination or a recipient"
  end

  test "cannot transfer to itself" do
    inventory = create(:inventory)
    transfer = build(:inventory_transfer, source_inventory: inventory, destination_inventory: inventory)

    refute transfer.valid?
    assert_includes transfer.errors.full_messages, "cannot be transferred to the inventory it came from"
  end

  test "source and destination read across both schemas" do
    fleet_inventory = create(:fleet_inventory)
    inventory = create(:inventory)

    transfer = build(:inventory_transfer, source_inventory: nil)
    transfer.source = fleet_inventory
    transfer.destination = inventory

    assert_equal fleet_inventory, transfer.source
    assert_equal inventory, transfer.destination
    assert_nil transfer.source_inventory
    assert_nil transfer.destination_fleet_inventory
  end

  test "assigning a destination clears the other column" do
    transfer = build(:inventory_transfer)
    transfer.destination = create(:fleet_inventory)
    transfer.destination = create(:inventory)

    assert_nil transfer.destination_fleet_inventory
    assert_instance_of Inventory, transfer.destination
  end

  test "a transfer with a recipient is not immediate" do
    assert build(:inventory_transfer, :to_inventory).immediate?
    refute build(:inventory_transfer, :to_user).immediate?
    refute build(:inventory_transfer, :to_fleet).immediate?
  end

  test "sender_party is the party holding the source, not the person who pressed the button" do
    fleet_inventory = create(:fleet_inventory)
    member = create(:user)
    transfer = build(:inventory_transfer, :to_user, source_inventory: nil,
      source_fleet_inventory: fleet_inventory, initiated_by: member)

    assert_equal fleet_inventory.fleet, transfer.sender_party
  end

  test "only pending transfers can be answered" do
    transfer = create(:inventory_transfer, :to_user)

    assert transfer.accept!
    assert transfer.completed?
    refute transfer.decline
    assert transfer.completed?
  end

  test "each terminal state stamps its own timestamp" do
    {decline!: :declined_at, cancel!: :cancelled_at, expire!: :expired_at, accept!: :completed_at}
      .each do |event, column|
      transfer = create(:inventory_transfer, :to_user)
      transfer.public_send(event)

      assert_not_nil transfer.reload.public_send(column), "#{event} did not stamp #{column}"
    end
  end
end
