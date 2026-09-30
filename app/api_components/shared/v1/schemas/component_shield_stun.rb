# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShieldStun
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            minAlphaDamageRatio: {type: :number},
            maxAlphaDamageRatio: {type: :number},
            minStunTime: {type: :number},
            maxStunTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
