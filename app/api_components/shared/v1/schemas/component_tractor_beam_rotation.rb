# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTractorBeamRotation
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxAngularVelocity: {type: :number},
            degreesPerAction: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
