# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What an attachment does to the gun it sits on, as multipliers. Only what it changes is listed.
      class EquipmentModifier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            damage: {type: :number},
            fireRate: {type: :number},
            projectileSpeed: {type: :number},
            heat: {type: :number},
            soundRadius: {type: :number},
            spread: ::Shared::V1::Schemas::ComponentWeaponSpread,
            recoil: ::Shared::V1::Schemas::EquipmentModifierRecoil,
            zoom: {type: :number},
            secondZoom: {type: :number},
            zoomTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
