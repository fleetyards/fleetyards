# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObjectMinimal < CelestialObject
      include SchemaConcern

      schema({
        properties: {
          parent: {"$ref": "#/components/schemas/CelestialObject", nullable: true},
          moons: {type: :array, items: {"$ref" => "#/components/schemas/CelestialObject"}},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[starsystem createdAt updatedAt]
      })
    end
  end
end
