# frozen_string_literal: true

module Payouts
  class Settlement
    # A contract has a client and contractors rather than a crew splitting a
    # take. The fleet is the payer: the reward it holds is divided across the
    # contractors by the weight Contracts::Progress gave them, and the expenses
    # they fronted are reimbursed on top of it rather than out of it -- a
    # contractor who bought the goods is made whole before any reward is divided,
    # and the reward they were promised does not shrink because they did.
    #
    #   pool    = total income (the reward, held by the fleet)
    #   share_c = pool * w_c / sum of the contractors' weights
    #   share_f = profit - pool = -(total expenses)
    #
    # The fleet's negative share is what makes it send the expenses as well as
    # the reward, and it keeps the shares summing to the profit, so the
    # balances still sum to zero.
    module ContractPayout
      def self.shares(participants:, profit_minor:, expenses_minor:)
        payers, payees = participants.partition { |participant| participant.fleet_id.present? }

        # Nobody to pay yet: the money stays with whoever holds it rather than
        # dividing by nothing.
        return EqualShares.shares(participants: participants, profit_minor: profit_minor, expenses_minor: expenses_minor) if payers.empty? || payees.empty?

        pool_minor = profit_minor + expenses_minor

        [
          [payees, pool_minor],
          [payers, -expenses_minor]
        ].each_with_object({}) do |(group, total), result|
          Settlement.divide(total, group).each_with_index do |share, index|
            result[group[index].id] = share
          end
        end
      end
    end
  end
end
