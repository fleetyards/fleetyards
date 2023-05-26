# frozen_string_literal: true

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
          description: {type: :string},
          grade: {type: :string, nullable: true},
          size: {type: :string, nullable: true},
          type: {type: :string, nullable: true},
          typeLabel: {type: :string, nullable: true},
          itemType: {type: :string, nullable: true},
          itemTypeLabel: {type: :string, nullable: true},
          weaponClass: {type: :string, nullable: true},
          weaponClassLabel: {type: :string, nullable: true},
          slot: {type: :string, nullable: true},
          slotLabel: {type: :string, nullable: true},
          damageReduction: {type: :string, nullable: true},
          rateOfFire: {type: :string, nullable: true},
          range: {type: :string, nullable: true},
          extras: {type: :string, nullable: true},
          storage: {type: :string, nullable: true},
          volume: {type: :string, nullable: true},
          temperatureRating: {type: :string, nullable: true},
          backpackCompatibility: {type: :string, nullable: true},
          coreCompatibility: {type: :string, nullable: true},
          media: {
            storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
          },
          storeImageIsFallback: {type: :boolean, deprecated: true},
          storeImage: {type: :string, deprecated: true},
          storeImageLarge: {type: :string, deprecated: true},
          storeImageMedium: {type: :string, deprecated: true},
          storeImageSmall: {type: :string, deprecated: true},
          soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
          boughtAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
          listedAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}},
          manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true}
        },
        required: %w[id name slug storeImageIsFallback]
      })

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
