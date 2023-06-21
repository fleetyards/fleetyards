# frozen_string_literal: true

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
              angledView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              fleetchartImage: {type: :string, nullable: true},
              # frontView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              sideView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true},
              topView: {"$ref": "#/components/schemas/ViewImage", nullable: true}
            }
          },
          nameWithModel: {type: :string, nullable: true},
          rsiId: {type: :integer, nullable: true},
          rsiName: {type: :string, nullable: true},
          rsiSlug: {type: :string, nullable: true},

          angledView: {type: :string, format: :uri, nullable: true, deprecated: true},
          angledViewHeight: {type: :number, nullable: true, deprecated: true},
          angledViewLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          angledViewMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          angledViewSmall: {type: :string, format: :uri, nullable: true, deprecated: true},
          angledViewWidth: {type: :number, nullable: true, deprecated: true},
          angledViewXlarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          fleetchartImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          hasStoreImage: {type: :boolean, nullable: true},
          sideView: {type: :string, format: :uri, nullable: true, deprecated: true},
          sideViewHeight: {type: :number, nullable: true, deprecated: true},
          sideViewLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          sideViewMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          sideViewSmall: {type: :string, format: :uri, nullable: true, deprecated: true},
          sideViewWidth: {type: :number, nullable: true, deprecated: true},
          sideViewXlarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, nullable: true, deprecated: true},
          topView: {type: :string, format: :uri, nullable: true, deprecated: true},
          topViewHeight: {type: :number, nullable: true, deprecated: true},
          topViewLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          topViewMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          topViewSmall: {type: :string, format: :uri, nullable: true, deprecated: true},
          topViewWidth: {type: :number, nullable: true, deprecated: true},
          topViewXlarge: {type: :string, format: :uri, nullable: true, deprecated: true}
        },
        required: %w[id name slug availability media]
      })
    end
  end
end
