# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelAvailability
        include OpenapiRuby::Components::Base

        # Ships can also be rented, which is why this is not ItemAvailability.

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
            },
            rentalAt: {
              type: :array,
              items: {"$ref": "#/components/schemas/ItemPrice"}
            }
          },
          additionalProperties: false,
          required: %w[boughtAt soldAt rentalAt]

        })
      end
    end
  end
end
