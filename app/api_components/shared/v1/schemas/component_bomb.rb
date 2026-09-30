# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Distances in metres, times in seconds, angles in degrees.
      class ComponentBomb
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            damagePerShot: ComponentWeaponDamage,
            maxLifetime: {type: :number},
            maxDropAngle: {type: :number},
            armTime: {type: :number},
            safetyDistance: {type: :number},
            blastRadiusMin: {type: :number},
            blastRadiusMax: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
