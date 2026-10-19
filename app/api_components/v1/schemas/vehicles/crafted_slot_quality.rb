# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class CraftedSlotQuality
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            position: {type: :integer, minimum: 0, description: "The recipe slot, by its position in the blueprint"},
            quality: {type: :integer, minimum: 0, maximum: 1000, description: "Material quality on the game's 0-1000 scale"}
          },
          additionalProperties: false,
          required: %w[position quality]
        })
      end
    end
  end
end
