# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanAcquisitionUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            startKind: ::V1::Schemas::Enums::HangarPlanStartKindEnum,
            sourceVehicleId: {type: [:string, :null], format: :uuid},
            buybackPledgeId: {type: [:string, :null], format: :uuid},
            startModelId: {type: [:string, :null], format: :uuid},
            priceOverride: {type: [:number, :null], minimum: 0},
            usesBuybackToken: {type: :boolean},
            steps: {type: :array, items: ::V1::Schemas::Inputs::HangarPlanUpgradeStepInput}
          },
          additionalProperties: false
        })
      end
    end
  end
end
