# frozen_string_literal: true

module Inventories
  # Answering a transfer that is waiting: accepting it into an inventory,
  # turning it away, calling it back, or letting it time out.
  #
  # Every outcome except acceptance writes the same thing -- a deposit back into
  # the source -- because a refusal returns the goods rather than deleting the
  # record of them leaving. Only the state, and who is told, differ.
  class TransferResolver
    include ActiveModel::Model

    attr_reader :transfer

    def initialize(transfer, actor: nil)
      @transfer = transfer
      @actor = actor
      @authorizer = TransferAuthorizer.new(actor)
    end

    # The destination has to clear **two** checks, not one.
    #
    # The acceptor must be allowed to deposit there -- that is the obvious one,
    # and on its own it is not enough. A fleet officer answering for their fleet
    # may also deposit into their own hangar, so authorising the two ends
    # independently lets them name it and walk a fleet-addressed shipment
    # straight into a personal inventory, with the fleet's ledger never seeing
    # it. Goods addressed to a party land in that party's inventory.
    #
    # `destination` may be something callable, which is how a ship inventory is
    # accepted into: it does not exist until its first deposit, so it has to be
    # brought into existence *inside* this transaction -- a rejected acceptance
    # must not leave an empty inventory behind.
    def accept(destination)
      return false unless pending?
      return false unless may_answer?

      apply do
        resolved = destination.respond_to?(:call) ? destination.call : destination

        unless @authorizer.may_deposit_into?(resolved)
          errors.add(:base, :forbidden)
          raise ::ActiveRecord::Rollback
        end

        unless ::InventoryTransfer.party_of(resolved) == @transfer.recipient_party
          errors.add(:base, :destination_is_not_the_recipients)
          raise ::ActiveRecord::Rollback
        end

        @transfer.destination = resolved
        TransferExecutor.new(@transfer, actor: @actor).deliver
        @transfer.accept!
      end
    end

    def decline
      return false unless pending?
      return false unless may_answer?

      apply { return_goods_and(:decline!) }
    end

    # The sending side calling it back. Authorised against the source, because
    # that is where the goods are going.
    def cancel
      return false unless pending?

      unless @authorizer.may_withdraw_from?(@transfer.source)
        errors.add(:base, :forbidden)
        return false
      end

      apply { return_goods_and(:cancel!) }
    end

    # No actor: the sweeper is nobody, and the goods go home on their own.
    def expire
      return false unless pending?

      apply { return_goods_and(:expire!) }
    end

    # The row is locked and the state re-read *inside* the transaction. The
    # `pending?` checks above are a cheap early exit; on their own they leave a
    # window in which two requests both read `pending` and both write their
    # ledger effects before either transition lands -- two deposits for one
    # shipment, or a decline that returns goods an accept has already delivered.
    # `whiny_transitions: false` hides it, because the losing transition simply
    # returns false after its side effects are already written.
    #
    # Taken before the inventory lock `withdrawal_does_not_exceed_stock` uses,
    # which is the same order every other path takes.
    private def apply
      ::ActiveRecord::Base.transaction do
        @transfer.lock!

        unless @transfer.pending?
          errors.add(:base, :already_resolved)
          raise ::ActiveRecord::Rollback
        end

        @transfer.resolved_by = @actor if @actor.present?
        yield
      end

      errors.empty?
    rescue TransferExecutor::Rejected => e
      errors.merge!(e.record.errors)
      false
    end

    private def return_goods_and(event)
      # A source that no longer exists cannot take the goods back. It cannot
      # happen through the app -- a pending transfer refuses to let its source be
      # destroyed -- but the state still has to close rather than raise.
      TransferExecutor.new(@transfer, actor: @actor).return_to_source if @transfer.source.present?
      @transfer.public_send(event)
    end

    private def pending?
      return true if @transfer.pending?

      errors.add(:base, :already_resolved)
      false
    end

    private def may_answer?
      return true if @authorizer.may_answer_for?(@transfer.recipient_party)

      errors.add(:base, :forbidden)
      false
    end
  end
end
