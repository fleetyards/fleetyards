# frozen_string_literal: true

module V1
  module Schemas
    class Starsystem
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          danger: {type: :string},
          description: {type: :string},
          economy: {type: :string},
          locationLabel: {type: :string},
          mapX: {type: :string},
          mapY: {type: :string},
          population: {type: :string},
          size: {type: :string},
          status: {type: :string},
          type: {type: :string},

          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage"}
            },
            additionalProperties: false
          },

          celestialObjects: {type: :array, items: {"$ref": "#/components/schemas/CelestialObject"}},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},

          # DEPRECATED

          storeImage: {type: :string, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, deprecated: true}
        },
        additionalProperties: false,
        required: %w[name slug media createdAt updatedAt]
      })
    end
  end
end
