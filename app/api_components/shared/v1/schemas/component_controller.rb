# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentController
        include OpenapiRuby::Components::Base

        ANGULAR_VELOCITY = {
          type: :object,
          properties: {
            pitch: {type: :number},
            yaw: {type: :number},
            roll: {type: :number}
          },
          additionalProperties: false
        }.freeze

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
            scmSpeed: {type: :number},
            scmSpeedBoosted: {type: :number},
            reverseSpeedBoosted: {type: :number},
            maxSpeed: {type: :number},
            angularVelocity: ANGULAR_VELOCITY,
            boostedAngularVelocity: ANGULAR_VELOCITY,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
