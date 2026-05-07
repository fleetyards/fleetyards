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
            overchargeTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
