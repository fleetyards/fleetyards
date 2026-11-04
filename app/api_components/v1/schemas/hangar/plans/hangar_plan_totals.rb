# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanTotals
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "Plan costs in USD. Min and max differ while slots are undecided",
            properties: {
              spendMin: {type: :number},
              spendMax: {type: :number},
              routedSpend: {type: :number, description: "What the routes planned for decided slots cost"},
              maxSpend: {type: :number, description: "The most the plan can cost: undecided slots at their dearest ship, and units without a start at the store price"},
              meltCredit: {type: :number},
              startingCredit: {type: :number},
              creditTotal: {type: :number},
              buybackCash: {type: :number, description: "Buy-backs paid in new money: RSI takes store credit for one only against a buy-back token"},
              buybacksWithoutTokenCount: {type: :integer},
              buybackTokensUsed: {type: :integer, description: "Buy-backs the user marked to pay with store credit"},
              buybackTokensAvailable: {type: :integer, description: "Buy-back tokens the plan counts with: its own figure, else what the last buy-back sync read"},
              netMin: {type: :number},
              netMax: {type: :number},
              cashNeededMin: {type: :number},
              cashNeededMax: {type: :number},
              remainingCreditMin: {type: :number},
              remainingCreditMax: {type: :number},
              estimatedMeltsCount: {type: :integer},
              openSlotsCount: {type: :integer},
              decidedSlotsCount: {type: :integer},
              undecidedSlotsCount: {type: :integer},
              unresolvedCount: {type: :integer},
              complete: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[spendMin spendMax routedSpend maxSpend meltCredit startingCredit creditTotal buybackCash buybacksWithoutTokenCount buybackTokensUsed buybackTokensAvailable netMin netMax cashNeededMin cashNeededMax remainingCreditMin remainingCreditMax estimatedMeltsCount openSlotsCount decidedSlotsCount undecidedSlotsCount unresolvedCount complete]
          })
        end
      end
    end
  end
end
