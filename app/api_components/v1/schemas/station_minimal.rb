# frozen_string_literal: true

module V1
  module Schemas
    class StationMinimal < StationBase
      include SchemaConcern

      schema({
        properties: {
          celestialObject: {"$ref": "#/components/schemas/CelestialObject"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[createdAt updatedAt]
      })
    end
  end
end
