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
          type: {"$ref": "#/components/schemas/StationTypeEnum"},
          typeLabel: {type: :string},
          size: {"$ref": "#/components/schemas/StationSizeEnum"},
          sizeLabel: {type: :string},
          classification: {"$ref": "#/components/schemas/StationClassificationEnum"},
          classificationLabel: {type: :string},
          description: {type: :string},
          dockCounts: {type: :array, items: {"$ref": "#/components/schemas/DockCount"}},
          habitable: {type: :boolean},
          habitationCounts: {type: :array, items: {"$ref": "#/components/schemas/HabitationCount"}},
          hasImages: {type: :boolean},
          locationLabel: {type: :string},
          location: {type: :string},

          media: {
            type: :object,
            properties: {
              backgroundImage: {type: :string},
              storeImage: {"$ref": "#/components/schemas/MediaImage"}
            },
            additionalProperties: false
          },

          refinery: {type: :boolean},
          shopListLabel: {type: :string},

          celestialObject: {"$ref": "#/components/schemas/CelestialObject"},
          starsystem: {"$ref": "#/components/schemas/Starsystem"},
          shops: {type: :array, items: {"$ref": "#/components/schemas/Shop"}},
          docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
          habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},

          # DEPRECATED

          backgroundImage: {type: :string, format: :uri, deprecated: true},
          storeImage: {type: :string, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, deprecated: true}
        },
        additionalProperties: false,
        required: %w[
          name slug type typeLabel size sizeLabel classification classificationLabel habitable hasImages media refinery cargoHub celestialObject createdAt
          updatedAt
        ]
      })
    end
  end
end
