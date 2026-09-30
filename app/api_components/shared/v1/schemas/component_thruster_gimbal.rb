# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentThrusterGimbal
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # How far an articulated nozzle swings, in degrees from centre.
            minPitch: {type: :number},
            maxPitch: {type: :number},
            minYaw: {type: :number},
            maxYaw: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
