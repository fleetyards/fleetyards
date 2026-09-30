# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What it takes to break a component and bring it back. Every part is
      # optional: an item the game gives no health, repair or distortion block
      # has none of it, and one without distortion cannot be distorted.
      class ComponentDurability
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            health: {type: :number},
            # Kilograms.
            mass: {type: :number},
            resistances: ComponentDamageMultipliers,
            selfRepair: ComponentSelfRepair,
            distortion: ComponentDistortion
          },
          additionalProperties: false
        })
      end
    end
  end
end
