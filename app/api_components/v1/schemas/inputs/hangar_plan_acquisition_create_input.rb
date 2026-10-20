# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanAcquisitionCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            candidateId: {type: :string, format: :uuid},
            startKind: ::V1::Schemas::Enums::HangarPlanStartKindEnum,
            sourceVehicleId: {type: [:string, :null], format: :uuid},
            buybackPledgeId: {type: [:string, :null], format: :uuid},
            startModelId: {type: [:string, :null], format: :uuid},
            priceOverride: {type: [:number, :null], minimum: 0},
            steps: {type: :array, items: ::V1::Schemas::Inputs::HangarPlanUpgradeStepInput}
          },
          required: %w[candidateId startKind],
          additionalProperties: false
        })
      end
    end
  end
end
