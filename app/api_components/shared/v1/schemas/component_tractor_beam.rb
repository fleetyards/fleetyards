# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeam
        include OpenapiRuby::Components::Base

        POWER_RANGE_ENTRY = {
          type: :object,
          properties: {
            start: {type: :number},
            modifier: {type: :number}
          },
          additionalProperties: false
        }.freeze

        POWER_RANGES = {
          type: :object,
          properties: {
            low: POWER_RANGE_ENTRY,
            medium: POWER_RANGE_ENTRY,
            high: POWER_RANGE_ENTRY
          },
          additionalProperties: false
        }.freeze

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
            rotation: {
              type: :object,
              properties: {
                maxAngularVelocity: {type: :number},
                degreesPerAction: {type: :number}
              },
              additionalProperties: false
            },
            movement: {
              type: :object,
              properties: {
                maxSpeed: {type: :number},
                maxAcceleration: {type: :number}
              },
              additionalProperties: false
            },
            cargoMode: {
              type: :object,
              properties: {
                maxForce: {type: :number},
                minDistance: {type: :number},
                maxDistance: {type: :number},
                fullStrengthDistance: {type: :number}
              },
              additionalProperties: false
            },
            towing: {
              type: :object,
              properties: {
                towingForce: {type: :number},
                towingMaxDistance: {type: :number},
                towingMaxAcceleration: {type: :number},
                quantumTowMassLimit: {type: :number}
              },
              additionalProperties: false
            },
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: POWER_RANGES
          },
          additionalProperties: false,
          required: %w[tractorBeam]
        })
      end
    end
  end
end
