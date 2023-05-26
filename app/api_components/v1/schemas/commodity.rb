# frozen_string_literal: true

module V1
  module Schemas
    class Commodity
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          type: {type: :string, nullable: true},
          typeLabel: {type: :string, nullable: true},
          media: {
            storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
          },
          storeImageIsFallback: {type: :boolean, deprecated: true},
          storeImage: {type: :string, deprecated: true},
          storeImageLarge: {type: :string, deprecated: true},
          storeImageMedium: {type: :string, deprecated: true},
          storeImageSmall: {type: :string, deprecated: true},
          soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
          boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
        },
        required: %w[id name slug createdAt updatedAt]
      }

      schema :minimal, {
        properties: {
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[createdAt updatedAt]
      }, extends: :base
    end
  end
end
