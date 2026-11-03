# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a piece of personal gear does, read from the game files. Each section is present only
      # for the gear it applies to.
      class EquipmentStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fireModes: {type: :array, items: ::Shared::V1::Schemas::EquipmentFireMode},
            toolActions: {type: :array, items: ::Shared::V1::Schemas::EquipmentToolAction},
            ammo: ::Shared::V1::Schemas::EquipmentAmmo,
            secondaryAmmo: ::Shared::V1::Schemas::EquipmentAmmo,
            magazine: ::Shared::V1::Schemas::EquipmentMagazine,
            regen: ::Shared::V1::Schemas::EquipmentRegen,
            heat: ::Shared::V1::Schemas::EquipmentHeat,
            melee: ::Shared::V1::Schemas::EquipmentMelee,
            modifier: ::Shared::V1::Schemas::EquipmentModifier,
            explosion: ::Shared::V1::Schemas::EquipmentExplosion,
            mine: ::Shared::V1::Schemas::EquipmentMine,
            mining: ::Shared::V1::Schemas::EquipmentMining,
            consumable: ::Shared::V1::Schemas::EquipmentConsumable
          },
          additionalProperties: false
        })
      end
    end
  end
end
