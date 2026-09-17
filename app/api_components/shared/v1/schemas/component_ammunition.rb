# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Carried by the 376 components that hold ammunition of their own.
      class ComponentAmmunition
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxAmmoCount: {type: :number},
            initialAmmoCount: {type: :number},
            maxRestockCount: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
