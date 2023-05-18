# frozen_string_literal: true

module V1
  module Schemas
    class Equipment
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          description: {type: :string},
          grade: {type: :string},
          size: {type: :string},
          type: {type: :string},
          typeLabel: {type: :string},
          itemType: {type: :string},
          itemTypeLabel: {type: :string},
          weaponClass: {type: :string},
          weaponClassLabel: {type: :string},
          slot: {type: :string},
          slotLabel: {type: :string},
          damageReduction: {type: :string},
          rateOfFire: {type: :string},
          range: {type: :string},
          extras: {type: :string},
          storage: {type: :string},
          storeImageIsFallback: {type: :boolean},
          storeImage: {type: :string},
          storeImageLarge: {type: :string},
          storeImageMedium: {type: :string},
          storeImageSmall: {type: :string},
          soldAt: {"$ref" => "#/components/schemas/ShopEquipment", :nullable => true},
          boughtAt: {"$ref" => "#/components/schemas/ShopEquipment", :nullable => true},
          manufacturer: {"$ref" => "#/components/schemas/Manufacturer", :nullable => true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[id name slug storeImageIsFallback createdAt updatedAt]
      }
    end
  end
end
