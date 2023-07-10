# frozen_string_literal: true

module V1
  module Schemas
    class ModelModulePackage
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          description: {type: :string, nullable: true},
          modules: {type: :array, items: {"$ref": "#/components/schemas/ModelModule"}},
          pledgePrice: {type: :number, nullable: true},
          media: {
            type: :object,
            properties: {
              angledView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              sideView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true},
              topView: {"$ref": "#/components/schemas/ViewImage", nullable: true}
            }
          },

          hasStoreImage: {type: :boolean, deprecated: true},
          storeImage: {type: :string, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, deprecated: true},
          angledView: {type: :string, nullable: true, deprecated: true},
          angledViewHeight: {type: :number, nullable: true, deprecated: true},
          angledViewLarge: {type: :string, nullable: true, deprecated: true},
          angledViewMedium: {type: :string, nullable: true, deprecated: true},
          angledViewSmall: {type: :string, nullable: true, deprecated: true},
          angledViewWidth: {type: :number, nullable: true, deprecated: true},
          angledViewXlarge: {type: :string, nullable: true, deprecated: true},
          sideView: {type: :string, nullable: true, deprecated: true},
          sideViewHeight: {type: :number, nullable: true, deprecated: true},
          sideViewLarge: {type: :string, nullable: true, deprecated: true},
          sideViewMedium: {type: :string, nullable: true, deprecated: true},
          sideViewSmall: {type: :string, nullable: true, deprecated: true},
          sideViewWidth: {type: :number, nullable: true, deprecated: true},
          sideViewXlarge: {type: :string, nullable: true, deprecated: true},
          topView: {type: :string, nullable: true, deprecated: true},
          topViewHeight: {type: :number, nullable: true, deprecated: true},
          topViewLarge: {type: :string, nullable: true, deprecated: true},
          topViewMedium: {type: :string, nullable: true, deprecated: true},
          topViewSmall: {type: :string, nullable: true, deprecated: true},
          topViewWidth: {type: :number, nullable: true, deprecated: true},
          topViewXlarge: {type: :string, nullable: true, deprecated: true}
        },
        additionalProperties: false,
        required: %w[id name]
      })
    end
  end
end
