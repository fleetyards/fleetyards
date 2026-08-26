# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeam
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            tractorBeam: {type: :boolean},
            minForce: {type: :number},
            maxForce: {type: :number},
            minDistance: {type: :number},
            maxDistance: {type: :number},
            fullStrengthDistance: {type: :number},
            maxAngle: {type: :number},
            maxVolume: {type: :number},
            volumeForceCoefficient: {type: :number},
            tetherBreakTime: {type: :number},
            heatPerSecond: {type: :number},
            rotation: ComponentTractorBeamRotation,
            movement: ComponentTractorBeamMovement,
            cargoMode: ComponentTractorBeamCargoMode,
            towing: ComponentTractorBeamTowing,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges
          },
          additionalProperties: false,
          required: %w[tractorBeam]
        })
      end
    end
  end
end
