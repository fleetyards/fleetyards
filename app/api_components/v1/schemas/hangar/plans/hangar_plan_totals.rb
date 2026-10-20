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
              meltCredit: {type: :number},
              startingCredit: {type: :number},
              creditTotal: {type: :number},
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
            required: %w[spendMin spendMax meltCredit startingCredit creditTotal netMin netMax cashNeededMin cashNeededMax remainingCreditMin remainingCreditMax estimatedMeltsCount openSlotsCount decidedSlotsCount undecidedSlotsCount unresolvedCount complete]
          })
        end
      end
    end
  end
end
