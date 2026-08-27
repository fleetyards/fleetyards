# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Where a tradeable item can be bought and sold. The UEX snapshot prices
      # items at every terminal that trades them, and commodities, components,
      # equipment, modules and paints all carry the same shape.
      class ItemAvailability
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            boughtAt: {
              type: :array,
              items: {"$ref": "#/components/schemas/ItemPrice"}
            },
            soldAt: {
              type: :array,
              items: {"$ref": "#/components/schemas/ItemPrice"}
            }
          },
          additionalProperties: false,
          required: %w[boughtAt soldAt]
        })
      end
    end
  end
end
