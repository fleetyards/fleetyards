# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeamCargoMode
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxForce: {type: :number},
            minDistance: {type: :number},
            maxDistance: {type: :number},
            fullStrengthDistance: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
