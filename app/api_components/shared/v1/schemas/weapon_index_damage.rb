# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Four damage types only; the full weapon component carries six.
      class WeaponIndexDamage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            physical: {type: :number},
            energy: {type: :number},
            distortion: {type: :number},
            thermal: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
