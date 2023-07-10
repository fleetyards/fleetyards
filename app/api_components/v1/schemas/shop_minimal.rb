# frozen_string_literal: true

module V1
  module Schemas
    class ShopMinimal < Shop
      include SchemaConcern

      schema({
        properties: {
          celestialObject: {"$ref": "#/components/schemas/CelestialObject"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[celestialObject createdAt updatedAt]
      })
    end
  end
end
