# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The round a magazine loads.
      class EquipmentAmmo
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            damage: ::Shared::V1::Schemas::ComponentWeaponDamage,
            damageDrop: ::Shared::V1::Schemas::EquipmentDamageDrop,
            speed: {type: :number},
            lifetime: {type: :number},
            range: {type: :number},
            penetration: ::Shared::V1::Schemas::EquipmentPenetration,
            explosion: ::Shared::V1::Schemas::EquipmentExplosion
          },
          additionalProperties: false
        })
      end
    end
  end
end
