# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class StarsystemMinimal < Starsystem
        include SchemaConcern

        schema({
          properties: {
            celestialObjects: {type: :array, items: {"$ref": "#/components/schemas/CelestialObject"}},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[celestialObjects createdAt updatedAt]
        })
      end
    end
  end
end
