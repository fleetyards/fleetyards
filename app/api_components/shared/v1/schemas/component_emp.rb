# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentEmp
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            chargeTime: {type: :number},
            unleashTime: {type: :number},
            cooldownTime: {type: :number},
            distortionDamage: {type: :number},
            # Radii in metres: the distortion burst, and the physical shove.
            empRadius: {type: :number},
            minEmpRadius: {type: :number},
            physRadius: {type: :number},
            minPhysRadius: {type: :number},
            pressure: {type: :number},
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
