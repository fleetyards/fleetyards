# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentMissileController
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxArmedMissiles: {type: :integer},
            # Seconds between two launches.
            launchCooldown: {type: :number},
            # Degrees; the controller's lock cone.
            lockAngle: {type: :number},
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
