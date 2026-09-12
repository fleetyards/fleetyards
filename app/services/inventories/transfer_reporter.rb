# frozen_string_literal: true

module Inventories
  # Filing a report against a transfer.
  #
  # It is not only a request for somebody to look. Reporting **declines the
  # transfer and denies the sender**, in the same transaction, so the reporter
  # gets relief immediately rather than waiting on a queue for something they
  # could already do themselves. The report is the additional step.
  #
  # No automatic sanction follows from any number of these. A threshold that
  # locked an account out would be a way to weaponise the report button, and at
  # the volumes this feature can produce a human reviewing each one is entirely
  # feasible.
  class TransferReporter
    include ActiveModel::Model

    attr_reader :report

    def initialize(transfer, actor:, reason:, note: nil, on_behalf_of: nil)
      @transfer = transfer
      @actor = actor
      @reason = reason
      @note = note
      @party = on_behalf_of || transfer.recipient_party
      @authorizer = TransferAuthorizer.new(actor)
    end

    def call
      return false unless may_report?

      ::ActiveRecord::Base.transaction do
        @report = build_report

        unless @report.save
          errors.merge!(@report.errors)
          raise ::ActiveRecord::Rollback
        end

        deny_the_sender
        decline_the_transfer
      end

      errors.empty? && @report&.persisted?
    end

    private def build_report
      ::InventoryTransferReport.new(
        inventory_transfer: @transfer,
        reporter: @actor,
        fleet: @party.is_a?(::Fleet) ? @party : nil,
        reason: @reason,
        note: @note
      )
    end

    # Forward-looking, and only for this pair. A rule already there is left as
    # it is rather than flipped -- somebody who deliberately allowed this sender
    # and then reported one message should not silently keep the allowance, so
    # it becomes a denial, but an existing denial is not rewritten.
    private def deny_the_sender
      sender = @transfer.sender_party
      return if sender.blank? || sender == @party

      rule = ::InventoryTransferRule.between(holder: @party, subject: sender) ||
        ::InventoryTransferRule.new.tap do |new_rule|
          new_rule.holder = @party
          new_rule.subject = sender
        end

      rule.effect = :deny
      rule.created_by = @actor
      rule.save!
    end

    # A report on an answered transfer is still worth filing -- the evidence is
    # the point -- but there is nothing left to decline.
    private def decline_the_transfer
      return unless @transfer.pending?

      resolver = TransferResolver.new(@transfer, actor: @actor)
      return if resolver.decline

      errors.merge!(resolver.errors)
      raise ::ActiveRecord::Rollback
    end

    private def may_report?
      return true if @authorizer.may_answer_for?(@party)

      errors.add(:base, :forbidden)
      false
    end
  end
end
