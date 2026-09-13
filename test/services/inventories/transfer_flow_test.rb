# frozen_string_literal: true

require "test_helper"

module Inventories
  # The move itself: what leaves, what arrives, and what comes back.
  class TransferFlowTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @source = create(:inventory, holder: @user)
      @destination = create(:inventory, holder: @user)
      @entry = create(:inventory_item, inventory: @source, name: "Titanium",
        category: :commodity, unit: :scu, quantity: 96)
      @position = @entry.position

      enable_transfers(@user)
    end

    test "an immediate transfer moves stock and completes on the spot" do
      builder = build_transfer(destination: @destination, quantity: 32)

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.completed?
      assert_equal 64, net(@source, "Titanium")
      assert_equal 32, net(@destination, "Titanium")
    end

    test "both sides of an immediate transfer are written in one transaction" do
      builder = build_transfer(destination: @destination, quantity: 32)

      TransferExecutor.any_instance.stubs(:deliver).raises(ActiveRecord::Rollback)

      builder.call

      assert_equal 96, net(@source, "Titanium"), "the withdrawal must not survive a failed delivery"
    end

    test "a cross-party transfer withdraws now and deposits only on acceptance" do
      recipient = create(:user)
      enable_transfers(recipient)
      target = create(:inventory, holder: recipient)

      builder = build_transfer(recipient: recipient, quantity: 40)

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.pending?
      assert_equal 56, net(@source, "Titanium"), "the goods leave on send"
      assert_equal 0, net(target, "Titanium")

      resolver = TransferResolver.new(builder.transfer, actor: recipient)

      assert resolver.accept(target), resolver.errors.full_messages.to_sentence
      assert_equal 40, net(target, "Titanium")
      assert builder.transfer.reload.completed?
    end

    test "declining returns the goods by deposit rather than by deletion" do
      recipient = create(:user)
      enable_transfers(recipient)
      builder = build_transfer(recipient: recipient, quantity: 40)
      builder.call

      assert TransferResolver.new(builder.transfer, actor: recipient).decline

      assert_equal 96, net(@source, "Titanium")
      assert_equal 3, @source.inventory_items.count, "the withdrawal and its compensating deposit both remain"
      assert builder.transfer.reload.declined?
    end

    test "cancelling is the sender calling it back" do
      recipient = create(:user)
      enable_transfers(recipient)
      builder = build_transfer(recipient: recipient, quantity: 40)
      builder.call

      refute TransferResolver.new(builder.transfer, actor: recipient).cancel,
        "the recipient cannot cancel; that is the sender's move"

      assert TransferResolver.new(builder.transfer, actor: @user).cancel
      assert_equal 96, net(@source, "Titanium")
    end

    test "expiry sends the goods home with no actor" do
      recipient = create(:user)
      enable_transfers(recipient)
      builder = build_transfer(recipient: recipient, quantity: 40)
      builder.call
      builder.transfer.update!(expires_at: 1.day.ago)

      ExpireTransfersJob.new.perform

      assert builder.transfer.reload.expired?
      assert_equal 96, net(@source, "Titanium")
    end

    test "escrow means the same stock cannot be sent twice" do
      recipient = create(:user)
      enable_transfers(recipient)

      assert build_transfer(recipient: recipient, quantity: 96).call

      second = build_transfer(recipient: recipient, quantity: 96)

      refute second.call
      assert_equal 0, net(@source, "Titanium")
    end

    test "one bad line rejects the whole shipment" do
      other = create(:inventory_item, inventory: @source, name: "Medpen",
        category: :consumable, unit: :units, quantity: 5)

      builder = TransferBuilder.new(
        source: @source, actor: @user, destination: @destination,
        lines: [
          {position_id: @position.id, quantity: 10},
          {position_id: other.position.id, quantity: 500}
        ]
      )

      refute builder.call
      assert_equal 96, net(@source, "Titanium"), "the good line must not have moved"
      assert_equal 5, net(@source, "Medpen")
    end

    test "a transfer moves several positions at once" do
      create(:inventory_item, inventory: @source, name: "Medpen",
        category: :consumable, unit: :units, quantity: 5)

      builder = TransferBuilder.new(
        source: @source, actor: @user, destination: @destination,
        lines: @source.positions.map { |position| {position_id: position.id, quantity: 2} }
      )

      assert builder.call, builder.errors.full_messages.to_sentence
      assert_equal 2, net(@destination, "Titanium")
      assert_equal 2, net(@destination, "Medpen")
    end

    test "a stranger cannot send from an inventory they do not hold" do
      builder = TransferBuilder.new(
        source: @source, actor: create(:user), destination: @destination,
        lines: [{position_id: @position.id, quantity: 1}]
      )

      refute builder.call
    end

    private def build_transfer(quantity:, destination: nil, recipient: nil)
      TransferBuilder.new(
        source: @source, actor: @user, destination:, recipient:,
        lines: [{position_id: @position.id, quantity:}]
      )
    end

    private def net(inventory, name)
      inventory.reload.stock_positions.find { |row| row.name == name }&.net_quantity.to_i
    end

    private def enable_transfers(actor)
      Flipper.enable_actor(:inventory_transfers, actor)
      Flipper.enable_actor(:hangar_inventories, actor)
    end
  end
end
