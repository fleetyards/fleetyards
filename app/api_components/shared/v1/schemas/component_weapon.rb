# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeapon
        include OpenapiRuby::Components::Base

        POWER_RANGE_ENTRY = {
          type: :object,
          properties: {
            start: {type: :number},
            modifier: {type: :number}
          },
          additionalProperties: false
        }.freeze

        POWER_RANGES = {
          type: :object,
          properties: {
            low: POWER_RANGE_ENTRY,
            medium: POWER_RANGE_ENTRY,
            high: POWER_RANGE_ENTRY
          },
          additionalProperties: false
        }.freeze

        schema({
          type: :object,
          properties: {
            beam: {type: :boolean},
            fireRate: {type: :number},
            heatPerShot: {type: :number},
            powerConsumption: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number},
            damagePerShot: {
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
            },
            damagePerSecond: {
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
            },
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
            regen: {
              type: :object,
              properties: {
                maxAmmoLoad: {type: :number},
                maxRegenPerSecond: {type: :number},
                costPerBullet: {type: :number},
                regenerationCooldown: {type: :number},
                requestedRegenPerSecond: {type: :number},
                requestedAmmoLoad: {type: :number}
              },
              additionalProperties: false
            },
            heat: {
              type: :object,
              properties: {
                overheatTemperature: {type: :number},
                coolingPerSecond: {type: :number},
                timeTillCoolingStarts: {type: :number},
                overheatFixTime: {type: :number}
              },
              additionalProperties: false
            },
            penetration: {
              type: :object,
              properties: {
                maxThickness: {type: :number},
                baseDistance: {type: :number}
              },
              additionalProperties: false
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
