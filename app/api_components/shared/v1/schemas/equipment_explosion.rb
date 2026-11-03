# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A blast: a grenade's, a mine's, or the one a launcher's round sets off.
      class EquipmentExplosion
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            damage: ::Shared::V1::Schemas::ComponentWeaponDamage,
            minRadius: {type: :number},
            maxRadius: {type: :number},
            pressure: {type: :number},
            fuse: {type: :number, description: "Seconds from the throw"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
