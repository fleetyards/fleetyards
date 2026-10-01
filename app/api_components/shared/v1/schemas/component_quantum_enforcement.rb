# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumEnforcement
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            basePowerDrawFraction: {type: :number},
            pulsePowerFraction: {type: :number},
            jammerPowerFraction: {type: :number},
            jammerSettings: ComponentQuantumJammer,
            quantumInterdictionPulseSettings: ComponentQuantumInterdictionPulse,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
