# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintCostSlot
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, nullable: true},
            scKey: {type: :string, nullable: true},
            position: {type: :integer},

            # Every slot in the current build accepts exactly one material, but
            # the game files allow several and already carry the string for it,
            # so this stays an array.
            options: {type: :array, items: ::Shared::V1::Schemas::BlueprintCostOption},
            modifiers: {type: :array, items: ::Shared::V1::Schemas::BlueprintCostModifier}
          },
          additionalProperties: false,
          required: %w[position options modifiers]
        })
      end
    end
  end
end
