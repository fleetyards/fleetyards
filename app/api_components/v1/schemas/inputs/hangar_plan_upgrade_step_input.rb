# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanUpgradeStepInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sourceKind: ::V1::Schemas::Enums::HangarPlanUpgradeSourceEnum,
            fromModelId: {type: [:string, :null], format: :uuid},
            toModelId: {type: :string, format: :uuid},
            hangarPledgeItemId: {type: [:string, :null], format: :uuid},
            buybackPledgeId: {type: [:string, :null], format: :uuid},
            priceOverride: {type: [:number, :null], minimum: 0},
            usesBuybackToken: {type: :boolean}
          },
          required: %w[sourceKind toModelId],
          additionalProperties: false
        })
      end
    end
  end
end
