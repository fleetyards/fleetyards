# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeaponPenetration
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxThickness: {type: :number},
            baseDistance: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
