# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Modules
        class ModelModule
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},

              availability: {
                type: :object,
                properties: {
                  listedAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
                  boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
                  soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
                },
                additionalProperties: false,
                required: %w[listedAt boughtAt soldAt]
              },
              description: {type: :string, nullable: true},
              media: {
                type: :object,
                properties: {
                  storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
                },
                additionalProperties: false
              },
              pledgePrice: {type: :number, nullable: true},
              productionStatus: {type: :string, nullable: true},

              manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true},

              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"},

              # DEPRECATED

              hasStoreImage: {type: :boolean, deprecated: true},
              storeImage: {type: :string, format: :uri, deprecated: true},
              storeImageLarge: {type: :string, format: :uri, deprecated: true},
              storeImageMedium: {type: :string, format: :uri, deprecated: true},
              storeImageSmall: {type: :string, format: :uri, deprecated: true}
            },
            additionalProperties: false,
            required: %w[id name availability media createdAt updatedAt]
          })
        end
      end
    end
  end
end
