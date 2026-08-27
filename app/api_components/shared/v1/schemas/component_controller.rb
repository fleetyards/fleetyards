# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentController
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            scmSpeed: {type: :number},
            scmSpeedBoosted: {type: :number},
            reverseSpeedBoosted: {type: :number},
            maxSpeed: {type: :number},
            angularVelocity: ComponentAngularVelocity,
            boostedAngularVelocity: ComponentAngularVelocity,
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
