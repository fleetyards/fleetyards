# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Equipment
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

            backpackCompatibility: {type: :string},
            coreCompatibility: {type: :string},
            damageReduction: {type: :string},
            description: {type: :string},
            extras: {type: :string},
            grade: {type: :string},
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

            range: {type: :string},
            rateOfFire: {type: :string},
            size: {type: :string},
            slot: {type: :string},
            slotLabel: {type: :string},
            storage: {type: :string},
            temperatureRating: {type: :string},
            type: {type: :string},
            typeLabel: {type: :string},
            volume: {type: :string},
            weaponClass: {type: :string},
            weaponClassLabel: {type: :string},

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
