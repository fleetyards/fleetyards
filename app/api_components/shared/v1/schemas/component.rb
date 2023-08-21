# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Component
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
                listedAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
                soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
              },
              additionalProperties: false,
              required: %w[boughtAt listedAt soldAt]
            },

            class: {type: :string, nullable: true},
            grade: {type: :string, nullable: true},
            itemClass: {type: :string, nullable: true},
            itemClassLabel: {type: :string, nullable: true},
            manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true},

            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },

            size: {type: :string, nullable: true},
            trackingSignal: {type: :string, nullable: true},
            trackingSignalLabel: {type: :string, nullable: true},
            type: {type: :string, nullable: true},
            typeLabel: {type: :string, nullable: true},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"},

            # DEPRECATED

            storeImage: {type: :string, format: :uri, deprecated: true},
            storeImageIsFallback: {type: :boolean, deprecated: true},
            storeImageLarge: {type: :string, format: :uri, deprecated: true},
            storeImageMedium: {type: :string, format: :uri, deprecated: true},
            storeImageSmall: {type: :string, format: :uri, deprecated: true}
          },
          additionalProperties: false,
          required: %w[id name slug availability createdAt updatedAt]
        })
      end
    end
  end
end
