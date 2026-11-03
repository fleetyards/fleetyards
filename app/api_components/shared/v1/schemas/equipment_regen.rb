# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The pool an energy weapon or a tool refills instead of swapping a magazine.
      class EquipmentRegen
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            capacity: {type: :number},
            regenPerSecond: {type: :number},
            cooldown: {type: :number},
            costPerShot: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
