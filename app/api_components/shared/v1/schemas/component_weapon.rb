# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeapon
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            weaponClass: {type: :string},
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
            pelletsPerShot: {type: :integer},
            speed: {type: :number},
            range: {type: :number},
            ammoCost: {type: :integer}
          },
          additionalProperties: false
        })
      end
    end
  end
end
