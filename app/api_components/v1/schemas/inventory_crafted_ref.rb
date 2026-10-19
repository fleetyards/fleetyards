# frozen_string_literal: true

module V1
  module Schemas
    # What a crafted part was made from: the recipe, and the grade of material
    # in each of its graded slots, keyed by the slot's position in the recipe.
    class InventoryCraftedRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          blueprint: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string}
            },
            required: %w[id name slug]
          },
          qualities: {
            type: :object,
            additionalProperties: {type: :integer, minimum: 0, maximum: 1000}
          }
        },
        required: %w[blueprint qualities]
      })
    end
  end
end
