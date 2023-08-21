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

            backpackCompatibility: {type: :string, nullable: true},
            coreCompatibility: {type: :string, nullable: true},
            damageReduction: {type: :string, nullable: true},
            description: {type: :string},
            extras: {type: :string, nullable: true},
            grade: {type: :string, nullable: true},
            itemType: {type: :string, nullable: true},
            itemTypeLabel: {type: :string, nullable: true},
            manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true},

            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },

            range: {type: :string, nullable: true},
            rateOfFire: {type: :string, nullable: true},
            size: {type: :string, nullable: true},
            slot: {type: :string, nullable: true},
            slotLabel: {type: :string, nullable: true},
            storage: {type: :string, nullable: true},
            temperatureRating: {type: :string, nullable: true},
            type: {type: :string, nullable: true},
            typeLabel: {type: :string, nullable: true},
            volume: {type: :string, nullable: true},
            weaponClass: {type: :string, nullable: true},
            weaponClassLabel: {type: :string, nullable: true},

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
