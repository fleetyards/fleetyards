# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentAngularVelocity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            pitch: {type: :number},
            yaw: {type: :number},
            roll: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
