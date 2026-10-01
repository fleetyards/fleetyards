# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeaponGimbalMode
        include OpenapiRuby::Components::Base

        # Multipliers that apply while the gun runs in gimbal mode. A spread
        # multiplier is absent when the game's record does not settle it.
        schema({
          type: :object,
          properties: {
            fireRateMultiplier: {type: :number},
            spreadMinMultiplier: {type: :number},
            spreadMaxMultiplier: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
