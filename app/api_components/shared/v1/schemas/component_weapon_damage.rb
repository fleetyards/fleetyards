# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Damage split by type, used for both the per-shot and the per-second
      # figure.
      class ComponentWeaponDamage
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
