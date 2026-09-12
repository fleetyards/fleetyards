# frozen_string_literal: true

module Inventories
  # Turns a request -- some positions, some quantities, and a target -- into a
  # transfer, and carries it out as far as it is allowed to go.
  #
  # All-or-nothing. If one line names a position that is not there, or asks for
  # more than the position holds, the whole set is refused rather than a partial
  # shipment leaving. A partial unload is not something the interface could
  # offer to undo.
  class TransferBuilder
    include ActiveModel::Model

    attr_reader :transfer, :refusal

    def initialize(source:, actor:, lines:, destination: nil, recipient: nil, note: nil)
      @source = source
      @actor = actor
      @requested_lines = Array(lines)
      @destination = destination
      @recipient = recipient
      @note = note
      @authorizer = TransferAuthorizer.new(actor)
    end

    def call
      return false unless authorized_to_send?
      return false unless lines_resolve?
      return false unless target_resolves?

      ::ActiveRecord::Base.transaction do
        # The recipient row is taken before the gate counts what is waiting for
        # them. The cap is a check-then-insert, so without this two sends near
        # the limit both read the same count and both write a row -- which is
        # precisely the burst the cap exists to stop. Locking the party makes
        # the second wait and re-read what the first left.
        #
        # Before the inventory lock `withdrawal_does_not_exceed_stock` takes,
        # keeping one lock order across every path.
        @recipient.lock! if @recipient.present?

        unless permitted_by_gate?
          raise ::ActiveRecord::Rollback
        end

        @transfer = build_transfer

        unless @transfer.save
          errors.merge!(@transfer.errors)
          raise ::ActiveRecord::Rollback
        end

        TransferExecutor.new(@transfer, actor: @actor).dispatch(lines)

        complete_immediately if immediate?
      end

      errors.empty? && @transfer&.persisted?
    rescue TransferExecutor::Rejected => e
      errors.merge!(e.record.errors)
      false
    end

    # A transfer whose initiator could have made the deposit themselves: there
    # is nobody to ask, so it is carried out on the spot.
    def immediate?
      @destination.present? && @authorizer.may_deposit_into?(@destination)
    end

    def lines
      @lines ||= @requested_lines.filter_map { |line| resolve_line(line) }
    end

    private def build_transfer
      transfer = ::InventoryTransfer.new(initiated_by: @actor, note: @note)
      transfer.source = @source

      if immediate?
        transfer.destination = @destination
      else
        transfer.recipient_party = @recipient
        transfer.expires_at = Time.current + ::InventoryTransfer::DEFAULT_TTL
      end

      transfer
    end

    private def complete_immediately
      TransferExecutor.new(@transfer, actor: @actor).deliver
      @transfer.resolved_by = @actor
      @transfer.accept!
    end

    private def authorized_to_send?
      return true if @authorizer.may_withdraw_from?(@source)

      errors.add(:base, :forbidden)
      false
    end

    private def lines_resolve?
      if @requested_lines.empty?
        errors.add(:lines, :blank)
        return false
      end

      if lines.size != @requested_lines.size
        errors.add(:lines, :invalid)
        return false
      end

      lines.all? { |line| quantity_available?(line) }
    end

    private def quantity_available?(line)
      if line.quantity <= 0
        errors.add(:quantity, :greater_than, count: 0)
        return false
      end

      return true if line.quantity <= line.stock_item.net_quantity.to_d

      errors.add(:quantity, :insufficient_stock,
        message: "exceeds current stock of #{line.position.name} (#{line.stock_item.net_quantity})")
      false
    end

    # Exactly one of the two, and a destination the sender may not deposit into
    # is not a destination -- it is a recipient they have to ask.
    private def target_resolves?
      if @destination.present?
        return true if immediate?

        # Naming an inventory you cannot write to would leak whether it exists.
        # The party that holds it is what a sender may address instead.
        errors.add(:base, :forbidden)
        return false
      end

      if @recipient.blank?
        errors.add(:base, :no_target)
        return false
      end

      if @recipient == sender_party
        errors.add(:base, :destination_is_source)
        return false
      end

      true
    end

    private def permitted_by_gate?
      return true if immediate?

      @refusal = TransferGate.new(sender: sender_party, recipient: @recipient, actor: @actor).refusal

      return true if @refusal.nil?

      errors.add(:base, @refusal.message)
      false
    end

    private def sender_party
      @sender_party ||= case @source
      when ::FleetInventory then @source.fleet
      else @source.holder
      end
    end

    private def resolve_line(line)
      attributes = line.respond_to?(:to_unsafe_h) ? line.to_unsafe_h : line
      attributes = attributes.symbolize_keys

      position = @source.positions.find_by(id: attributes[:position_id])
      return if position.blank?

      stock_item = @source.stock_item(position.slug)
      return if stock_item.blank?

      TransferLine.new(position:, stock_item:, quantity: attributes[:quantity].to_d)
    end
  end
end
