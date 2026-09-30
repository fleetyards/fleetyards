# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a mining laser or module does to the rock it works on, each as a
      # percent change. A modifier that changes nothing is left out.
      class ComponentMiningModifiers
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            instability: {type: :number},
            resistance: {type: :number},
            optimalChargeWindow: {type: :number},
            optimalChargeRate: {type: :number},
            catastrophicChargeRate: {type: :number},
            shatterDamage: {type: :number},
            inertMaterials: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
