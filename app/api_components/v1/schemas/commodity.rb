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
          type: {type: :string},
          typeLabel: {type: :string},
          storeImageIsFallback: {type: :boolean},
          storeImage: {type: :string},
          storeImageLarge: {type: :string},
          storeImageMedium: {type: :string},
          storeImageSmall: {type: :string},
          soldAt: {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true},
          boughtAt: {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[id name slug storeImageIsFallback createdAt updatedAt]
      }
    end
  end
end
