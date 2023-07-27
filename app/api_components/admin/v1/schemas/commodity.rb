# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Commodity
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
                soldAt: {type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}}
              },
              required: %w[boughtAt soldAt]
            },
            type: {type: :string, nullable: true},
            typeLabel: {type: :string, nullable: true},
            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              }
            }
          },
          additionalProperties: false,
          required: %w[id name slug availability]
        })
      end
    end
  end
end
