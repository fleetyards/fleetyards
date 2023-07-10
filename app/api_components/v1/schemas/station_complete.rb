# frozen_string_literal: true

module V1
  module Schemas
    class StationComplete < Station
      include SchemaConcern

      schema({
        properties: {
          starsystem: {"$ref": "#/components/schemas/Starsystem"},
          shops: {type: :array, items: {"$ref": "#/components/schemas/Shop"}},
          docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
          habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},
          images: {type: :array, items: {"$ref": "#/components/schemas/Image"}},
          celestialObject: {"$ref": "#/components/schemas/CelestialObjectMinimal"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[createdAt updatedAt]
      })
    end
  end
end
