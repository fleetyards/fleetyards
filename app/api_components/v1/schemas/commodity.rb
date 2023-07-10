# frozen_string_literal: true

module V1
  module Schemas
    class Commodity
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},

          availability: {
            type: :object,
            properties: {
              boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
              soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
            },
            required: %w[boughtAt soldAt]
          },
          type: {type: :string, nullable: true},
          typeLabel: {type: :string, nullable: true},
          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
            }
          },

          storeImage: {type: :string, format: :uri, deprecated: true},
          storeImageIsFallback: {type: :boolean, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, deprecated: true}
        },
        additionalProperties: false,
        required: %w[id name slug availability media createdAt updatedAt]
      })
    end
  end
end
