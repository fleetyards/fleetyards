# frozen_string_literal: true

module Contracts
  # Whether a transfer may be filed under a contract.
  #
  # Deliberately narrow. This decides only that the link is *allowed*; whether
  # the goods actually count is `Progress`'s question, asked later against the
  # entries, so a transfer addressed to the fleet that gets accepted into the
  # wrong inventory is refused nothing here and simply counts for nothing.
  #
  # A refused link is an error, never a silently unlinked transfer: a contractor
  # who filed a delivery under a contract and got an ordinary transfer back
  # would have no way to tell until the progress bar failed to move.
  class TransferLink
    MANAGE_PRIVILEGES = ["fleet:manage", "fleet:contracts:manage"].freeze

    attr_reader :error

    def initialize(contract:, actor:, source:, destination: nil, recipient: nil)
      @contract = contract
      @actor = actor
      @source = source
      @destination = destination
      @recipient = recipient
    end

    def call
      return refuse(:contract_not_found) if @contract.blank?
      return refuse(:contract_not_open) unless @contract.in_progress?
      return refuse(:not_a_contractor) unless may_act?
      return refuse(:contract_end_not_involved) unless touches_contract?

      true
    end

    # Either somebody the contract is being worked by, or somebody who answers
    # for the fleet -- an officer dispatching a pickup on a member's behalf is
    # ordinary. Neither of them is thereby paid for it: `Progress` attributes
    # goods to the party whose inventory they left.
    private def may_act?
      return false if @actor.blank?
      return true if @contract.contractor?(@actor)

      membership = @actor.fleet_memberships.kept.find_by(fleet_id: @contract.fleet_id)
      membership&.accepted? && membership.has_access?(MANAGE_PRIVILEGES)
    end

    # One end has to be somewhere the contract named, or the transfer has to be
    # addressed to whoever answers for its destination: the fleet that posted
    # it, or the author whose own inventory it delivers into. Without this any
    # two inventories could be filed under any contract the actor happens to
    # work on.
    private def touches_contract?
      ends = @contract.tracked_inventory_ids
      return true if @source.is_a?(::FleetInventory) && ends.include?(@source.id)
      return true if @destination.present? && ends.include?(@destination.id)
      return true if @recipient.is_a?(::Fleet) && @recipient.id == @contract.fleet_id

      addressed_to_author?
    end

    # Only for the people working it. A fleet manager may otherwise act on any
    # contract, and this would let one file fleet stock into a member's private
    # inventory as contract work.
    private def addressed_to_author?
      @contract.hangar_destination? &&
        @recipient.is_a?(::User) && @recipient == @contract.created_by &&
        @contract.contractor?(@actor)
    end

    private def refuse(code)
      @error = code
      false
    end
  end
end
