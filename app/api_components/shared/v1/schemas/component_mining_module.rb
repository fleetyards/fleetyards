# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentMiningModule
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            miningModule: {type: :boolean},
            activation: ::Shared::V1::Schemas::Enums::ComponentMiningModuleActivationEnum,
            # Active modules only: how many times, and for how many seconds each.
            charges: {type: :integer},
            duration: {type: :number},
            # Percent change to the laser's fracturing and extraction power.
            fracturePower: {type: :number},
            extractionPower: {type: :number},
            modifiers: ComponentMiningModifiers
          },
          required: %w[miningModule activation],
          additionalProperties: false
        })
      end
    end
  end
end
