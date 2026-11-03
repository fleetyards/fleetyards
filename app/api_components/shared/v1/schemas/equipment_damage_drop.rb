# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # How a round loses damage over distance: from where, how much per metre, and down to what.
      class EquipmentDamageDrop
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            minDistance: {type: :number},
            perMeter: ::Shared::V1::Schemas::ComponentWeaponDamage,
            minDamage: ::Shared::V1::Schemas::ComponentWeaponDamage
          },
          additionalProperties: false
        })
      end
    end
  end
end
