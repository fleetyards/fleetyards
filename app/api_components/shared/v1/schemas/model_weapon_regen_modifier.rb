# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelWeaponRegenModifier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The ship's engineering buff on its energy guns: multipliers on the weapon power ratio, each gun's ammo load and its regen",
          properties: {
            powerRatio: {type: :number},
            maxAmmoLoad: {type: :number},
            maxRegenPerSecond: {type: :number}
          },
          additionalProperties: false,
          required: %w[powerRatio maxAmmoLoad maxRegenPerSecond]
        })
      end
    end
  end
end
