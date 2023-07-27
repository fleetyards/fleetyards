# frozen_string_literal: true

module V1
  module Schemas
    class ModelModule
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},

          availability: {
            type: :object,
            properties: {
              boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
              soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
            },
            required: %w[boughtAt soldAt]
          },
          description: {type: :string, nullable: true},
          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage"}
            }
          },
          pledgePrice: {type: :number, nullable: true},
          productionStatus: {type: :string, nullable: true},

          hasStoreImage: {type: :boolean, deprecated: true},
          storeImage: {type: :string, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, deprecated: true}
        },
        additionalProperties: false,
        required: %w[id name availability media]
      })
    end
  end
end
