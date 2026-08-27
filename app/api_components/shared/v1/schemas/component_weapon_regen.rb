# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeaponRegen
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxAmmoLoad: {type: :number},
            maxRegenPerSecond: {type: :number},
            costPerBullet: {type: :number},
            regenerationCooldown: {type: :number},
            requestedRegenPerSecond: {type: :number},
            requestedAmmoLoad: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
