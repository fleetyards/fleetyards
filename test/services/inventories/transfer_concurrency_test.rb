# frozen_string_literal: true

require "test_helper"

module Inventories
  # Two requests arriving at once. Every one of these passed before the row lock
  # went in, because `whiny_transitions: false` lets the losing transition return
  # false *after* its ledger effects are already written.
  class TransferConcurrencyTest < ActiveSupport::TestCase
    # Threads need real connections, so the wrapping transaction has to go.
    self.use_transactional_tests = false

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
      @target = create(:inventory, holder: @recipient)
    end

    # No wrapping transaction to roll back, so this cleans up after itself.
    # `destroy_all` on the users rather than `delete_all`: they own rows in half
    # a dozen tables and only the dependent callbacks know about them.
    teardown do
      InventoryTransferRule.delete_all
      InventoryTransferReport.delete_all
      InventoryItem.delete_all
      InventoryPosition.delete_all
      InventoryTransfer.delete_all
      Inventory.delete_all
      User.where(id: [@sender.id, @recipient.id]).destroy_all
    end

    test "two accepts deliver one shipment" do
      transfer = send_pending(40)

      outcomes = race(2) do
        TransferResolver.new(InventoryTransfer.find(transfer.id), actor: @recipient).accept(@target)
      end

      assert_equal 1, outcomes.count(true), "both accepts reported success"
      assert_equal 40, @target.reload.stock_positions.sole.net_quantity,
        "the shipment was delivered more than once"
    end

    test "an accept and a decline cannot both take effect" do
      transfer = send_pending(40)

      race(2) do |index|
        resolver = TransferResolver.new(InventoryTransfer.find(transfer.id), actor: @recipient)
        index.zero? ? resolver.accept(@target) : resolver.decline
      end

      delivered = @target.reload.stock_positions.sum { |row| row.net_quantity.to_i }
      returned = @source.reload.stock_positions.sole.net_quantity.to_i

      assert_equal 100, delivered + returned,
        "the goods were both delivered and returned (#{delivered} + #{returned})"
    end

    test "a cancel racing an accept resolves once" do
      transfer = send_pending(40)

      race(2) do |index|
        if index.zero?
          TransferResolver.new(InventoryTransfer.find(transfer.id), actor: @recipient).accept(@target)
        else
          TransferResolver.new(InventoryTransfer.find(transfer.id), actor: @sender).cancel
        end
      end

      assert_equal 1, InventoryTransfer.find(transfer.id).dispatched_entries.count
      delivered = @target.reload.stock_positions.sum { |row| row.net_quantity.to_i }
      returned = @source.reload.stock_positions.sole.net_quantity.to_i

      assert_equal 100, delivered + returned
    end

    private def send_pending(quantity)
      builder = TransferBuilder.new(
        source: @source, actor: @sender, recipient: @recipient,
        lines: [{position_id: @entry.position.id, quantity:}]
      )
      assert builder.call, builder.errors.full_messages.to_sentence
      builder.transfer
    end

    # A barrier, so both threads are inside the window rather than one simply
    # finishing first.
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
