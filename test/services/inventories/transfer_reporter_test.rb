# frozen_string_literal: true

require "test_helper"

module Inventories
  class TransferReporterTest < ActiveSupport::TestCase
    setup do
      @sender = create(:user)
      @recipient = create(:user)
      [@sender, @recipient].each do |actor|
        Flipper.enable_actor(:inventory_transfers, actor)
        Flipper.enable_actor(:hangar_inventories, actor)
      end

      @source = create(:inventory, holder: @sender)
      entry = create(:inventory_item, inventory: @source, name: "Titanium",
        category: :commodity, unit: :scu, quantity: 96)

      @builder = TransferBuilder.new(source: @source, actor: @sender, recipient: @recipient,
        lines: [{position_id: entry.position.id, quantity: 40}])
      @builder.call
      @transfer = @builder.transfer
    end

    test "reporting declines the transfer, returns the goods and denies the sender" do
      reporter = TransferReporter.new(@transfer, actor: @recipient, reason: :spam)

      assert reporter.call, reporter.errors.full_messages.to_sentence

      assert @transfer.reload.declined?
      assert_equal 96, @source.reload.stock_positions.sole.net_quantity,
        "the goods go home as part of the same transaction"

      rule = InventoryTransferRule.between(holder: @recipient, subject: @sender)

      assert rule.deny?
      assert_equal @recipient, reporter.report.reporter
    end

    test "the denied sender is then refused by the gate" do
      TransferReporter.new(@transfer, actor: @recipient, reason: :spam).call

      gate = TransferGate.new(sender: @sender, recipient: @recipient)

      refute gate.allowed?
      assert_equal :policy_closed, gate.refusal.code,
        "a denial must be indistinguishable from a closed policy"
    end

    test "a report flips an existing allowance to a denial" do
      create(:inventory_transfer_rule, :allow, user: @recipient, subject_user: @sender)

      TransferReporter.new(@transfer, actor: @recipient, reason: :spam).call

      assert InventoryTransferRule.between(holder: @recipient, subject: @sender).deny?
    end

    test "only somebody who could answer the transfer may report it" do
      reporter = TransferReporter.new(@transfer, actor: create(:user), reason: :spam)

      refute reporter.call
      assert @transfer.reload.pending?
    end

    test "one report per reporter per transfer" do
      assert TransferReporter.new(@transfer, actor: @recipient, reason: :spam).call

      second = TransferReporter.new(@transfer, actor: @recipient, reason: :scam)

      refute second.call
    end

    test "a reason of other needs a note" do
      reporter = TransferReporter.new(@transfer, actor: @recipient, reason: :other)

      refute reporter.call
      assert @transfer.reload.pending?, "a rejected report leaves the transfer alone"
    end

    test "the evidence survives without being copied" do
      TransferReporter.new(@transfer, actor: @recipient, reason: :spam).call

      report = InventoryTransferReport.sole

      assert_equal 40, report.inventory_transfer.dispatched_entries.sole.quantity
      assert_equal @sender, report.subject
    end

    test "a fleet report is filed on behalf of the fleet" do
      fleet = create(:fleet)
      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)
      Flipper.enable_actor(:inventory_transfers, fleet)
      Flipper.enable_actor(:fleet_logistics, fleet)

      entry = create(:inventory_item, inventory: @source, name: "Tungsten",
        category: :commodity, unit: :scu, quantity: 10)
      builder = TransferBuilder.new(source: @source, actor: @sender, recipient: fleet,
        lines: [{position_id: entry.position.id, quantity: 5}])
      builder.call

      reporter = TransferReporter.new(builder.transfer, actor: officer, reason: :spam)

      assert reporter.call, reporter.errors.full_messages.to_sentence
      assert_equal fleet, reporter.report.fleet
      assert InventoryTransferRule.between(holder: fleet, subject: @sender).deny?
    end
  end
end
