# frozen_string_literal: true

module Contracts
  # Moves a contract to `fulfilled` once the ledger says every line has landed.
  #
  # Run from `InventoryTransfer`'s `after_commit`, so the deposits it is about
  # to count are already committed and visible.
  #
  # The lock is not decoration. `whiny_transitions: false` means a losing
  # transition returns false *after* its writes -- so two final deliveries
  # completing at once would both read an incomplete contract, both recompute,
  # and both call `fulfil!`. Taking the row and re-reading inside the
  # transaction makes the second one see the state the first left.
  class Fulfilment
    def initialize(contract)
      @contract = contract
    end

    def call
      return false if @contract.blank?

      @contract.with_lock do
        return false unless @contract.in_progress?
        return false unless Progress.new(@contract).complete?

        next false unless @contract.fulfil!

        ActiveSupport::Notifications.instrument("fleet_contract.fulfilled", contract: @contract)
        true
      end
    end
  end
end
