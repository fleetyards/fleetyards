# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDriveJumpHeat
        include OpenapiRuby::Components::Base

        # The heat a drive puts out in each phase of a jump.
        schema({
          type: :object,
          properties: {
            preRampUp: {type: :number},
            rampUp: {type: :number},
            inFlight: {type: :number},
            rampDown: {type: :number},
            postRampDown: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
