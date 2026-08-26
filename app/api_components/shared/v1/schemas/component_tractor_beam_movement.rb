# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeamMovement
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxSpeed: {type: :number},
            maxAcceleration: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
