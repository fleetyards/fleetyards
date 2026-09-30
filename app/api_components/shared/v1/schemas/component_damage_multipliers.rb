# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The share of each damage type a component takes: 1 is all of it, 0.1
      # a tenth.
      class ComponentDamageMultipliers
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            physical: {type: :number},
            energy: {type: :number},
            distortion: {type: :number},
            thermal: {type: :number},
            biochemical: {type: :number},
            stun: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
