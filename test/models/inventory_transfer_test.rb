# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: inventory_transfers
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("pending"), not null
#  cancelled_at                   :datetime
#  completed_at                   :datetime
#  declined_at                    :datetime
#  expired_at                     :datetime
#  expires_at                     :datetime
#  note                           :text
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  destination_fleet_inventory_id :uuid
#  destination_inventory_id       :uuid
#  initiated_by_id                :uuid
#  recipient_fleet_id             :uuid
#  recipient_id                   :uuid
#  resolved_by_id                 :uuid
#  source_fleet_inventory_id      :uuid
#  source_inventory_id            :uuid
#
# Indexes
#
#  index_inventory_transfers_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_inventory_transfers_on_destination_inventory_id        (destination_inventory_id)
#  index_inventory_transfers_on_initiated_by_id                 (initiated_by_id)
#  index_inventory_transfers_on_pending_expires_at              (expires_at) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_pending_recipient               (recipient_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_pending_recipient_fleet         (recipient_fleet_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_recipient_fleet_id              (recipient_fleet_id)
#  index_inventory_transfers_on_recipient_id                    (recipient_id)
#  index_inventory_transfers_on_resolved_by_id                  (resolved_by_id)
#  index_inventory_transfers_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#  index_inventory_transfers_on_source_inventory_id             (source_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (destination_inventory_id => inventories.id) ON DELETE => nullify
#  fk_rails_...  (initiated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (recipient_fleet_id => fleets.id) ON DELETE => nullify
#  fk_rails_...  (recipient_id => users.id) ON DELETE => nullify
#  fk_rails_...  (resolved_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (source_inventory_id => inventories.id) ON DELETE => nullify
#
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
