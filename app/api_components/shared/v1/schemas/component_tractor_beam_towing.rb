# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeamTowing
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            towingForce: {type: :number},
            towingMaxDistance: {type: :number},
            towingMaxAcceleration: {type: :number},
            quantumTowMassLimit: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
