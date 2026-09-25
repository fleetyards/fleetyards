# frozen_string_literal: true

module Payouts
  class Settlement
    # An event or a tour: everyone on the ledger is in it together, so the
    # profit divides across all of them by weight.
    module EqualShares
      def self.shares(participants:, profit_minor:, expenses_minor:)
        Settlement.divide(profit_minor, participants)
          .each_with_index.to_h { |share, index| [participants[index].id, share] }
      end
    end
  end
end
