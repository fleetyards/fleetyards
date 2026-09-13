# frozen_string_literal: true

require "test_helper"

module Inventories
  class TransferGateTest < ActiveSupport::TestCase
    setup do
      @sender = create(:user)
      @recipient = create(:user)
      enable_transfers(@sender)
      enable_transfers(@recipient)
    end

    test "an open recipient admits a stranger" do
      assert gate.allowed?
      assert_nil gate.refusal
    end

    test "a closed recipient refuses" do
      @recipient.update!(inventory_transfer_policy: :nobody)

      assert_equal :policy_closed, gate.refusal.code
    end

    test "known admits somebody you share a fleet with, and nobody else" do
      @recipient.update!(inventory_transfer_policy: :known)

      assert_equal :policy_restricted, gate.refusal.code

      fleet = create(:fleet)
      create(:fleet_membership, :accepted, fleet:, user: @sender)
      create(:fleet_membership, :accepted, fleet:, user: @recipient)

      assert gate.allowed?
    end

    test "a denial is indistinguishable from a closed policy" do
      create(:inventory_transfer_rule, user: @recipient, subject_user: @sender, effect: :deny)

      denied = gate.refusal

      @recipient.update!(inventory_transfer_policy: :nobody)
      InventoryTransferRule.destroy_all
      closed = gate.refusal

      assert_equal closed.code, denied.code
      assert_equal closed.message, denied.message
    end

    test "an allowance overrides a closed policy" do
      @recipient.update!(inventory_transfer_policy: :nobody)
      create(:inventory_transfer_rule, :allow, user: @recipient, subject_user: @sender)

      assert gate.allowed?
    end

    test "an allowance overrides a full inbox" do
      InventoryTransfer::OUTSTANDING_LIMIT.times { create(:inventory_transfer, recipient: @recipient) }

      assert_equal :cap_reached, gate.refusal.code

      create(:inventory_transfer_rule, :allow, user: @recipient, subject_user: @sender)

      assert gate.allowed?
    end

    test "an allowance does not override a sanction" do
      @sender.block_transfers!(reason: "spam")
      create(:inventory_transfer_rule, :allow, user: @recipient, subject_user: @sender)

      assert_equal :sender_blocked, gate.refusal.code
    end

    test "an allowance does not override a missing feature flag" do
      Flipper.disable_actor(:inventory_transfers, @recipient)
      create(:inventory_transfer_rule, :allow, user: @recipient, subject_user: @sender)

      assert_equal :unavailable, gate.refusal.code
    end

    test "the cap counts only pending transfers to this recipient" do
      InventoryTransfer::OUTSTANDING_LIMIT.times do
        create(:inventory_transfer, recipient: @recipient, aasm_state: "declined")
      end
      create(:inventory_transfer, recipient: create(:user))

      assert gate.allowed?
    end

    test "the sanction is checked before the recipient's own stance" do
      @sender.block_transfers!(reason: "spam")
      @recipient.update!(inventory_transfer_policy: :nobody)

      assert_equal :sender_blocked, gate.refusal.code,
        "a sanctioned sender must be told it is them, not the recipient"
    end

    test "a fleet recipient answers on its own policy and its own flags" do
      fleet = create(:fleet)
      Flipper.enable_actor(:inventory_transfers, fleet)
      Flipper.enable_actor(:fleet_logistics, fleet)

      assert TransferGate.new(sender: @sender, recipient: fleet).allowed?

      fleet.reload.update!(inventory_transfer_policy: :known)

      assert_equal :policy_restricted, TransferGate.new(sender: @sender, recipient: fleet).refusal.code

      create(:fleet_membership, :accepted, fleet:, user: @sender)

      assert TransferGate.new(sender: @sender, recipient: fleet).allowed?
    end

    test "a fleet sender can be sanctioned too" do
      fleet = create(:fleet).reload
      fleet.block_transfers!(reason: "spam")

      assert_equal :sender_blocked, TransferGate.new(sender: fleet, recipient: @recipient).refusal.code
    end

    # The serialised error has to carry a stable code; the human sentence
    # belongs in the message beside it.
    test "a refusal reaches the caller as a code, not as a sentence" do
      @recipient.update!(inventory_transfer_policy: :nobody)

      source = create(:inventory, holder: @sender)
      entry = create(:inventory_item, inventory: source, quantity: 10)

      builder = ::Inventories::TransferBuilder.new(
        source:, actor: @sender, recipient: @recipient,
        lines: [{position_id: entry.position.id, quantity: 1}]
      )

      refute builder.call
      assert_equal [:policy_closed], builder.errors.details[:base].map { |d| d[:error] }
      assert_equal [I18n.t("inventory_transfers.refusals.policy_closed")],
        builder.errors[:base]
    end

    private def gate
      TransferGate.new(sender: @sender, recipient: @recipient)
    end

    private def enable_transfers(actor)
      Flipper.enable_actor(:inventory_transfers, actor)
      Flipper.enable_actor(:hangar_inventories, actor)
    end
  end
end
