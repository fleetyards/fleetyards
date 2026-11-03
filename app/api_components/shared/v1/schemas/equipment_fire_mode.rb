# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One mode a weapon fires in. Alpha and DPS are derived: per shot across its pellets, and
      # sustained while the trigger is held, before a reload. A charged mode's are at full charge.
      class EquipmentFireMode
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            label: {type: :string},
            kind: ::Shared::V1::Schemas::Enums::EquipmentFireModeKindEnum,
            condition: ::Shared::V1::Schemas::EquipmentFireModeCondition,
            fireRate: {type: :number, description: "Rounds per minute"},
            shots: {type: :integer, description: "Rounds per burst"},
            cooldown: {type: :number},
            pellets: {type: :integer},
            ammoCost: {type: :integer},
            damageMultiplier: {type: :number},
            heatPerShot: {type: :number},
            heatPerSecond: {type: :number},
            spread: ::Shared::V1::Schemas::ComponentWeaponSpread,
            charge: ::Shared::V1::Schemas::EquipmentCharge,
            damagePerSecond: ::Shared::V1::Schemas::ComponentWeaponDamage,
            fullDamageRange: {type: :number},
            zeroDamageRange: {type: :number},
            chargeUpTime: {type: :number},
            alpha: {type: :number},
            dps: {type: :number},
            timeToOverheat: {type: :number},
            shotsToOverheat: {type: :integer}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
