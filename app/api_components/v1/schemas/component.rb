# frozen_string_literal: true

module V1
  module Schemas
    class Component
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          grade: {type: :string},
          class: {type: :string},
          size: {type: :string},
          type: {type: :string},
          typeLabel: {type: :string},
          itemClass: {type: :string},
          itemClassLabel: {type: :string},
          trackingSignal: {type: :string},
          trackingSignalLabel: {type: :string},
          storeImageIsFallback: {type: :boolean},
          storeImage: {type: :string},
          storeImageLarge: {type: :string},
          storeImageMedium: {type: :string},
          storeImageSmall: {type: :string},
          soldAt: {"$ref" => "#/components/schemas/ShopComponent", :nullable => true},
          boughtAt: {"$ref" => "#/components/schemas/ShopComponent", :nullable => true},
          manufacturer: {"$ref" => "#/components/schemas/Manufacturer", :nullable => true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[id name slug storeImageIsFallback createdAt updatedAt]
      }
    end
  end
end
