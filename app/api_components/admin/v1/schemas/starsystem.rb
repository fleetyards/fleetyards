# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Starsystem
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            danger: {type: :string, nullable: true},
            description: {type: :string, nullable: true},
            economy: {type: :string, nullable: true},
            locationLabel: {type: :string, nullable: true},
            mapX: {type: :string, nullable: true},
            mapY: {type: :string, nullable: true},
            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
              }
            },
            population: {type: :string, nullable: true},
            size: {type: :string, nullable: true},
            status: {type: :string, nullable: true},
            type: {type: :string, nullable: true},
            storeImage: {type: :string, format: :uri, deprecated: true},
            storeImageLarge: {type: :string, format: :uri, deprecated: true},
            storeImageMedium: {type: :string, format: :uri, deprecated: true},
            storeImageSmall: {type: :string, format: :uri, deprecated: true}
          },
          additionalProperties: false,
          required: %w[name slug]
        })
      end
    end
  end
end
