# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentJumpDrive
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            alignmentRate: {type: :number},
            alignmentDecayRate: {type: :number},
            tuningRate: {type: :number},
            tuningDecayRate: {type: :number},
            fuelUsageEfficiencyMultiplier: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
