# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanAcquisitionCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            candidateId: {type: :string, format: :uuid, description: "The ship of the plan the route leads to"},
            slotId: {type: :string, format: :uuid, description: "A slot with no ship yet, which holds the start until it gets one; given instead of candidateId"},
            startKind: ::V1::Schemas::Enums::HangarPlanStartKindEnum,
            sourceVehicleId: {type: [:string, :null], format: :uuid},
            buybackPledgeId: {type: [:string, :null], format: :uuid},
            startModelId: {type: [:string, :null], format: :uuid},
            priceOverride: {type: [:number, :null], minimum: 0},
            usesBuybackToken: {type: :boolean},
            steps: {type: :array, items: ::V1::Schemas::Inputs::HangarPlanUpgradeStepInput}
          },
          required: %w[startKind],
          additionalProperties: false
        })
      end
    end
  end
end
