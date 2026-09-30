# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeaponSpread
        include OpenapiRuby::Components::Base

        # The cone a gun's shots scatter into, in degrees: it opens from `min`
        # by `firstAttack` on the first shot and `attack` on each one after, up
        # to `max`, and closes at `decay` per second once firing stops.
        schema({
          type: :object,
          properties: {
            min: {type: :number},
            max: {type: :number},
            firstAttack: {type: :number},
            attack: {type: :number},
            decay: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
