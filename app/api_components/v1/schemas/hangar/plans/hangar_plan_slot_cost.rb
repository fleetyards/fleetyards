# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSlotCost
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              slotId: {type: :string, format: :uuid},
              state: ::V1::Schemas::Enums::HangarPlanSlotStateEnum,
              minCost: {type: :number},
              maxCost: {type: :number},
              storeCostMin: {type: [:number, :null], description: "The least those units could cost, starting from ships the plan leaves free; null when unknown"},
              storeCost: {type: [:number, :null], description: "What buying the units with no start yet would cost in USD, outside minCost and maxCost; null when unknown"},
              unresolvedCount: {type: :integer},
              complete: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[slotId state minCost maxCost storeCostMin storeCost unresolvedCount complete]
          })
        end
      end
    end
  end
end
