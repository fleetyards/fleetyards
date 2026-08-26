# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeapon
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            beam: {type: :boolean},
            fireRate: {type: :number},
            heatPerShot: {type: :number},
            powerConsumption: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            damagePerShot: ComponentWeaponDamage,
            damagePerSecond: ComponentWeaponDamage,
            heatPerSecond: {type: :number},
            pelletsPerShot: {type: :integer},
            speed: {type: :number},
            range: {type: :number},
            fullDamageRange: {type: :number},
            zeroDamageRange: {type: :number},
            ammoCost: {type: :integer},
            maxAmmo: {type: :integer},
            chargeTime: {type: :number},
            overchargeTime: {type: :number},
            regen: ComponentWeaponRegen,
            heat: ComponentWeaponHeat,
            penetration: ComponentWeaponPenetration
          },
          additionalProperties: false
        })
      end
    end
  end
end
