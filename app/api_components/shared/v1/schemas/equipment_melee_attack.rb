# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentMeleeAttack
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            category: {type: :string},
            damage: ::Shared::V1::Schemas::ComponentWeaponDamage,
            impulse: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
