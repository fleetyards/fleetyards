# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module ModulePackages
          class ModelModulePackage
            include SchemaConcern

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                name: {type: :string},
                description: {type: :string},
                pledgePrice: {type: :number},

                modules: {type: :array, items: {"$ref": "#/components/schemas/ModelModule"}},
                model: {"$ref": "#/components/schemas/Model"},

                media: {
                  type: :object,
                  properties: {
                    angledView: {"$ref": "#/components/schemas/ViewImage"},
                    sideView: {"$ref": "#/components/schemas/ViewImage"},
                    storeImage: {"$ref": "#/components/schemas/MediaImage"},
                    topView: {"$ref": "#/components/schemas/ViewImage"}
                  },
                  additionalProperties: false
                },

                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"},

                # DEPRECATED

                hasStoreImage: {type: :boolean, deprecated: true},
                storeImage: {type: :string, format: :uri, deprecated: true},
                storeImageLarge: {type: :string, format: :uri, deprecated: true},
                storeImageMedium: {type: :string, format: :uri, deprecated: true},
                storeImageSmall: {type: :string, format: :uri, deprecated: true},
                angledView: {type: :string, deprecated: true},
                angledViewHeight: {type: :number, deprecated: true},
                angledViewLarge: {type: :string, deprecated: true},
                angledViewMedium: {type: :string, deprecated: true},
                angledViewSmall: {type: :string, deprecated: true},
                angledViewWidth: {type: :number, deprecated: true},
                angledViewXlarge: {type: :string, deprecated: true},
                sideView: {type: :string, deprecated: true},
                sideViewHeight: {type: :number, deprecated: true},
                sideViewLarge: {type: :string, deprecated: true},
                sideViewMedium: {type: :string, deprecated: true},
                sideViewSmall: {type: :string, deprecated: true},
                sideViewWidth: {type: :number, deprecated: true},
                sideViewXlarge: {type: :string, deprecated: true},
                topView: {type: :string, deprecated: true},
                topViewHeight: {type: :number, deprecated: true},
                topViewLarge: {type: :string, deprecated: true},
                topViewMedium: {type: :string, deprecated: true},
                topViewSmall: {type: :string, deprecated: true},
                topViewWidth: {type: :number, deprecated: true},
                topViewXlarge: {type: :string, deprecated: true}
              },
              additionalProperties: false,
              required: %w[id name modules model media createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
