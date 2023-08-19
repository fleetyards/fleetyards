# frozen_string_literal: true

module V1
  module Schemas
    class Station
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          cargoHub: {type: :boolean},
          classificationLabel: {type: :string, nullable: true},
          classification: {type: :string, nullable: true},
          description: {type: :string, nullable: true},
          dockCounts: {type: :array, items: {"$ref": "#/components/schemas/DockCount"}},
          habitable: {type: :boolean},
          habitationCounts: {type: :array, items: {"$ref": "#/components/schemas/HabitationCount"}},
          hasImages: {type: :boolean},
          locationLabel: {type: :string, nullable: true},
          location: {type: :string, nullable: true},

          media: {
            type: :object,
            properties: {
              backgroundImage: {type: :string, nullable: true},
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
            },
            additionalProperties: false
          },

          refinery: {type: :boolean},
          shopListLabel: {type: :string, nullable: true},
          typeLabel: {type: :string, nullable: true},
          type: {type: :string, nullable: true},

          celestialObject: {"$ref": "#/components/schemas/CelestialObject"},
          starsystem: {"$ref": "#/components/schemas/Starsystem"},
          shops: {type: :array, items: {"$ref": "#/components/schemas/Shop"}},
          docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
          habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},

          # DEPRECATED

          backgroundImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, nullable: true, deprecated: true}
        },
        additionalProperties: false,
        required: %w[
          name slug habitable hasImages refinery cargoHub celestialObject media createdAt
          updatedAt
        ]
      })
    end
  end
end
