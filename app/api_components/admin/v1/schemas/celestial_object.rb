# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class CelestialObject
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            designation: {type: :string},
            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
              }
            },
            storeImage: {type: :string, format: :url, deprecated: true},
            storeImageLarge: {type: :string, deprecated: true},
            storeImageMedium: {type: :string, deprecated: true},
            storeImageSmall: {type: :string, deprecated: true},
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
            starsystem: {"$ref": "#/components/schemas/Starsystem", nullable: true}
          },
          additionalProperties: false,
          required: %w[id name slug designation]
        })
      end
    end
  end
end
