# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentLifeSupport
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Life-support units generated per second.
            lifeSupportGeneration: {type: :number},
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          additionalProperties: false,
          required: %w[lifeSupportGeneration]
        })
      end
    end
  end
end
