# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentRadar
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            signatureDetection: ComponentSignatureDetection,
            pingProperties: ComponentPingProperties,
            aimAssistRange: {type: :number},
            aimAssistMin: {type: :number},
            sensitivityModifiers: ComponentSensitivityModifiers,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
