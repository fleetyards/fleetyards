# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanAcquisitionUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            priceOverride: {type: [:number, :null], minimum: 0},
            steps: {type: :array, items: ::V1::Schemas::Inputs::HangarPlanUpgradeStepInput}
          },
          additionalProperties: false
        })
      end
    end
  end
end
