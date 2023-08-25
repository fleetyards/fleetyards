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
                listedAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
                boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
                soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
              },
              additionalProperties: false,
              required: %w[listedAt boughtAt soldAt]
            },

            class: {type: :string},
            grade: {type: :string},
            itemClass: {type: :string},
            itemClassLabel: {type: :string},
            itemType: {type: :string},
            itemTypeLabel: {type: :string},

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },

            size: {type: :string},
            trackingSignal: {type: :string},
            trackingSignalLabel: {type: :string},
            type: {type: :string},
            typeLabel: {type: :string},

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
          required: %w[id name slug availability media createdAt updatedAt]
        })
      end
    end
  end
end
