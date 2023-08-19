# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObject
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          designation: {type: :string},
          description: {type: :string, nullable: true},
          type: {type: :string, nullable: true},
          habitable: {type: :boolean, nullable: true},
          fairchanceact: {type: :boolean, nullable: true},
          subType: {type: :string, nullable: true},
          size: {type: :string, nullable: true},
          danger: {type: :integer, nullable: true},
          economy: {type: :integer, nullable: true},
          population: {type: :integer, nullable: true},
          locationLabel: {type: :string, nullable: true},

          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
            },
            additionalProperties: false
          },

          starsystem: {"$ref": "#/components/schemas/Starsystem"},
          parent: {"$ref": "#/components/schemas/CelestialObject"},
          moons: {type: :array, items: {"$ref" => "#/components/schemas/CelestialObject"}},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},

          # DEPRECATED

          storeImage: {type: :string, format: :url, deprecated: true},
          storeImageLarge: {type: :string, deprecated: true},
          storeImageMedium: {type: :string, deprecated: true},
          storeImageSmall: {type: :string, deprecated: true}
        },
        additionalProperties: false,
        required: %w[name slug designation starsystem createdAt updatedAt]
      })
    end
  end
end
