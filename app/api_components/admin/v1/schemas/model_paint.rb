# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ModelPaint
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string, nullable: true},
            slug: {type: :string, nullable: true},

            availability: {
              type: :object,
              properties: {
                boughtAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                soldAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                }
              },
              required: %w[boughtAt soldAt]
            },
            description: {type: :string, nullable: true},
            lastUpdatedAt: {type: :string, format: "date-time", nullable: true},
            lastUpdatedAtLabel: {type: :string, nullable: true},
            media: {
              type: :object,
              properties: {
                angledView: {"$ref": "#/components/schemas/ViewImage"},
                fleetchartImage: {type: :string, nullable: true},
                # frontView: {"$ref": "#/components/schemas/ViewImage"},
                sideView: {"$ref": "#/components/schemas/ViewImage"},
                storeImage: {"$ref": "#/components/schemas/MediaImage"},
                topView: {"$ref": "#/components/schemas/ViewImage"}
              }
            },
            nameWithModel: {type: :string, nullable: true},
            rsiId: {type: :integer, nullable: true},
            rsiName: {type: :string, nullable: true},
            rsiSlug: {type: :string, nullable: true}
          },
          additionalProperties: false,
          required: %w[id name slug availability media]
        })
      end
    end
  end
end
