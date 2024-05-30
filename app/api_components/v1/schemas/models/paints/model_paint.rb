# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Paints
        class ModelPaint
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              lastUpdatedAt: {type: :string, format: "date-time"},
              lastUpdatedAtLabel: {type: :string},

              availability: {
                type: :object,
                properties: {
                  boughtAt: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/ItemPrice"}
                  },
                  soldAt: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/ItemPrice"}
                  }
                },
                additionalProperties: false,
                required: %w[boughtAt soldAt]
              },

              media: {
                type: :object,
                properties: {
                  angledView: {"$ref": "#/components/schemas/ViewImage"},
                  fleetchartImage: {type: :string},
                  # frontView: {"$ref": "#/components/schemas/ViewImage"},
                  sideView: {"$ref": "#/components/schemas/ViewImage"},
                  storeImage: {"$ref": "#/components/schemas/MediaImage"},
                  topView: {"$ref": "#/components/schemas/ViewImage"}
                },
                additionalProperties: false
              },

              nameWithModel: {type: :string},
              rsiId: {type: :integer},
              rsiName: {type: :string},
              rsiSlug: {type: :string},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"},

              # DEPRECATED

              angledView: {type: :string, format: :uri, deprecated: true},
              angledViewHeight: {type: :number, deprecated: true},
              angledViewLarge: {type: :string, format: :uri, deprecated: true},
              angledViewMedium: {type: :string, format: :uri, deprecated: true},
              angledViewSmall: {type: :string, format: :uri, deprecated: true},
              angledViewWidth: {type: :number, deprecated: true},
              angledViewXlarge: {type: :string, format: :uri, deprecated: true},
              fleetchartImage: {type: :string, format: :uri, deprecated: true},
              hasStoreImage: {type: :boolean},
              sideView: {type: :string, format: :uri, deprecated: true},
              sideViewHeight: {type: :number, deprecated: true},
              sideViewLarge: {type: :string, format: :uri, deprecated: true},
              sideViewMedium: {type: :string, format: :uri, deprecated: true},
              sideViewSmall: {type: :string, format: :uri, deprecated: true},
              sideViewWidth: {type: :number, deprecated: true},
              sideViewXlarge: {type: :string, format: :uri, deprecated: true},
              storeImage: {type: :string, format: :uri, deprecated: true},
              storeImageLarge: {type: :string, format: :uri, deprecated: true},
              storeImageMedium: {type: :string, format: :uri, deprecated: true},
              storeImageSmall: {type: :string, format: :uri, deprecated: true},
              topView: {type: :string, format: :uri, deprecated: true},
              topViewHeight: {type: :number, deprecated: true},
              topViewLarge: {type: :string, format: :uri, deprecated: true},
              topViewMedium: {type: :string, format: :uri, deprecated: true},
              topViewSmall: {type: :string, format: :uri, deprecated: true},
              topViewWidth: {type: :number, deprecated: true},
              topViewXlarge: {type: :string, format: :uri, deprecated: true}
            },
            additionalProperties: false,
            required: %w[id name slug availability media createdAt updatedAt]
          })
        end
      end
    end
  end
end
