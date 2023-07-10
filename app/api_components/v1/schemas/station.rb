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
            }
          },
          refinery: {type: :boolean},
          shopListLabel: {type: :string, nullable: true},
          typeLabel: {type: :string, nullable: true},
          type: {type: :string, nullable: true},
          # Deprecated
          backgroundImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, nullable: true, deprecated: true}
        },
        required: %w[name slug habitable hasImages refinery cargoHub celestialObject media]
      })
    end
  end
end
