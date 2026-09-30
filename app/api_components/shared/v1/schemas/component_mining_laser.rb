# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentMiningLaser
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Fracturing beam power, from the throttle's floor to full.
            fracturePowerMin: {type: :number},
            fracturePowerMax: {type: :number},
            extractionPower: {type: :number},
            # Full power out to the optimal range, fading to nothing at the max.
            optimalRange: {type: :number},
            maxRange: {type: :number},
            chargeUpTime: {type: :number},
            chargeDownTime: {type: :number},
            moduleSlots: {type: :integer},
            modifiers: ComponentMiningModifiers
          },
          additionalProperties: false
        })
      end
    end
  end
end
