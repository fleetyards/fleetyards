# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelSpeeds
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            groundAcceleration: {type: :number},
            groundDecceleration: {type: :number},
            groundMaxSpeed: {type: :number},
            groundReverseSpeed: {type: :number},
            maxSpeed: {type: :number},
            pitch: {type: :number},
            pitchBoosted: {type: :number},
            roll: {type: :number},
            rollBoosted: {type: :number},
            scmSpeed: {type: :number},
            scmSpeedBoosted: {type: :number},
            reverseSpeedBoosted: {type: :number},
            yaw: {type: :number},
            yawBoosted: {type: :number}
          },
          additionalProperties: false

        })
      end
    end
  end
end
