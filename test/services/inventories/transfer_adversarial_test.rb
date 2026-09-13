# frozen_string_literal: true

require "test_helper"

# Trying to break the two invariants the design rests on.
module Inventories
  class TransferAdversarialTest < ActiveSupport::TestCase
    setup do
      @sender = create(:user)
      @recipient = create(:user)
      [@sender, @recipient].each do |actor|
        Flipper.enable_actor(:inventory_transfers, actor)
        Flipper.enable_actor(:hangar_inventories, actor)
      end

      @source = create(:inventory, holder: @sender)
      @entry = create(:inventory_item, inventory: @source, name: "Titanium",
        category: :commodity, unit: :scu, quantity: 100)
    end

    # --- escrow cannot be stranded ---------------------------------------

    # The third door onto goods in flight, after the inventory and the position.
    # Deleting the withdrawal un-withdraws the stock while the transfer still
    # promises it, and acceptance then delivers nothing and reports success.
    test "the withdrawal a pending transfer wrote cannot be deleted" do
      transfer = send_pending(40)
      withdrawal = transfer.dispatched_entries.sole

      refute withdrawal.destroy
      assert InventoryItem.exists?(withdrawal.id)
      assert_equal 60, @source.reload.stock_positions.sole.net_quantity
      assert_includes withdrawal.errors.full_messages.join(" "), "still waiting to be answered"
    end

    test "once the transfer is answered its entries are ordinary history again" do
      transfer = send_pending(40)
      TransferResolver.new(transfer, actor: @recipient).decline

      assert transfer.reload.dispatched_entries.sole.destroy
    end

    test "a position rename does not detach the shipment from the transfer" do
      transfer = send_pending(40)
      stock_item = @source.reload.stock_item(@entry.reload.position.slug)

      @source.update_stock_item(stock_item, {name: "Titanium Ore"})

      assert_equal 1, transfer.reload.dispatched_entries.count
      assert_equal "Titanium Ore", transfer.dispatched_entries.sole.name
    end

    test "accepting twice deposits once" do
      transfer = send_pending(40)
      target = create(:inventory, holder: @recipient)

      assert TransferResolver.new(transfer, actor: @recipient).accept(target)
      refute TransferResolver.new(transfer.reload, actor: @recipient).accept(target)

      assert_equal 40, target.reload.stock_positions.sole.net_quantity
    end

    test "declining after accepting does not return goods a second time" do
      transfer = send_pending(40)
      target = create(:inventory, holder: @recipient)
      TransferResolver.new(transfer, actor: @recipient).accept(target)

      refute TransferResolver.new(transfer.reload, actor: @recipient).decline

      assert_equal 60, @source.reload.stock_positions.sole.net_quantity
    end

    test "the sweeper cannot expire a transfer that was already answered" do
      transfer = send_pending(40)
      TransferResolver.new(transfer, actor: @recipient).decline
      transfer.update_columns(expires_at: 1.day.ago)

      ExpireTransfersJob.new.perform

      assert transfer.reload.declined?
      assert_equal 100, @source.reload.stock_positions.sole.net_quantity
    end

    # --- the gate cannot be reached by an authorised deposit --------------

    test "a self-addressed transfer is refused rather than gated" do
      builder = TransferBuilder.new(
        source: @source, actor: @sender, recipient: @sender,
        lines: [{position_id: @entry.position.id, quantity: 10}]
      )

      refute builder.call
      assert_equal 100, @source.reload.stock_positions.sole.net_quantity
    end

    test "a closed policy cannot block a move between my own inventories" do
      @sender.update!(inventory_transfer_policy: :nobody)
      @sender.block_transfers!(reason: "sanctioned")
      other = create(:inventory, holder: @sender)

      builder = TransferBuilder.new(
        source: @source, actor: @sender, destination: other,
        lines: [{position_id: @entry.position.id, quantity: 10}]
      )

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.completed?
    end

    # --- quantities -------------------------------------------------------

    test "a negative or zero quantity is refused" do
      [0, -5].each do |quantity|
        builder = TransferBuilder.new(
          source: @source, actor: @sender, destination: create(:inventory, holder: @sender),
          lines: [{position_id: @entry.position.id, quantity:}]
        )

        refute builder.call, "quantity #{quantity} was accepted"
      end

      assert_equal 100, @source.reload.stock_positions.sole.net_quantity
    end

    test "the same position named twice in one transfer cannot exceed stock" do
      builder = TransferBuilder.new(
        source: @source, actor: @sender, destination: create(:inventory, holder: @sender),
        lines: [
          {position_id: @entry.position.id, quantity: 60},
          {position_id: @entry.position.id, quantity: 60}
        ]
      )

      builder.call

      assert_operator @source.reload.stock_positions.sole.net_quantity, :>=, 0,
        "two lines over the same position drove it negative"
    end

    # --- goods land where they were addressed ----------------------------

    # Authorising the two ends independently is not enough: a fleet officer may
    # deposit into their own hangar as well as answer for the fleet, so naming
    # it would walk a fleet-addressed shipment into a personal inventory with
    # the fleet's ledger never seeing it.
    test "a fleet officer cannot accept a fleet's transfer into their own hangar" do
      fleet = create(:fleet)
      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)
      Flipper.enable_actor(:inventory_transfers, fleet)
      Flipper.enable_actor(:fleet_logistics, fleet)
      Flipper.enable_actor(:inventory_transfers, officer)
      Flipper.enable_actor(:hangar_inventories, officer)

      builder = TransferBuilder.new(
        source: @source, actor: @sender, recipient: fleet,
        lines: [{position_id: @entry.position.id, quantity: 40}]
      )

      assert builder.call, builder.errors.full_messages.to_sentence

      personal = create(:inventory, holder: officer)
      resolver = TransferResolver.new(builder.transfer, actor: officer)

      refute resolver.accept(personal)
      assert builder.transfer.reload.pending?
      assert_equal 0, personal.reload.inventory_items.count

      depot = create(:fleet_inventory, fleet:)

      assert TransferResolver.new(builder.transfer, actor: officer).accept(depot)
      assert_equal 40, depot.reload.stock_positions.sole.net_quantity
    end

    test "a user cannot accept their own transfer into somebody else's inventory" do
      transfer = send_pending(40)
      stranger = create(:inventory, holder: create(:user))

      refute TransferResolver.new(transfer, actor: @recipient).accept(stranger)
      assert transfer.reload.pending?
    end

    # --- the cap holds under a burst --------------------------------------

    test "the cap is enforced against the count as it stands, not as it was read" do
      InventoryTransfer::OUTSTANDING_LIMIT.times do
        create(:inventory_transfer, recipient: @recipient)
      end

      builder = TransferBuilder.new(
        source: @source, actor: @sender, recipient: @recipient,
        lines: [{position_id: @entry.position.id, quantity: 1}]
      )

      refute builder.call
      assert_equal 100, @source.reload.stock_positions.sole.net_quantity
      assert_equal InventoryTransfer::OUTSTANDING_LIMIT,
        InventoryTransfer.pending_for_user(@recipient).count
    end

    private def send_pending(quantity)
      builder = TransferBuilder.new(
        source: @source, actor: @sender, recipient: @recipient,
        lines: [{position_id: @entry.position.id, quantity:}]
      )
      assert builder.call, builder.errors.full_messages.to_sentence
      builder.transfer
    end
  end
end
