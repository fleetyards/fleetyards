# frozen_string_literal: true

module V1
  module Schemas
    class Shop < ShopMinimal
      include SchemaConcern

      schema({
        properties: {
          celestialObject: {"$ref": "#/components/schemas/CelestialObject"}
        },
        additionalProperties: false,
        required: %w[celestialObject]
      })
    end
  end
end
