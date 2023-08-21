# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ShopCommodity
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string, nullable: true},

            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },
            category: {"$ref": "#/components/schemas/ShopCommodityCategoryEnum"},
            subCategory: {
              anyOf: [{
                type: :string
              }, {
                "$ref": "#/components/schemas/ComponentClassEnum"
              }, {
                "$ref": "#/components/schemas/EquipmentTypeEnum"
              }, {
                "$ref": "#/components/schemas/CommodityTypeEnum"
              }]
            },
            subCategoryLabel: {type: :string},

            prices: {
              type: :object,
              properties: {
                averageBuyPrice: {type: :number},
                averageRentalPrice1Day: {type: :number},
                averageRentalPrice30Days: {type: :number},
                averageRentalPrice3Days: {type: :number},
                averageRentalPrice7Days: {type: :number},
                averageSellPrice: {type: :number},
                buyPrice: {type: :number},
                rentalPrice1Day: {type: :number},
                rentalPrice30Days: {type: :number},
                rentalPrice3Days: {type: :number},
                rentalPrice7Days: {type: :number},
                sellPrice: {type: :number},
                pricePerUnit: {type: :boolean}
              },
              additionalProperties: false,
              required: %w[pricePerUnit]
            },

            locationLabel: {type: :string},
            confirmed: {type: :boolean},

            commodityItemType: {"$ref": "#/components/schemas/ShopCommodityItemTypeEnum"},
            commodityItemId: {type: :string, format: :uuid},

            shop: {"$ref": "#/components/schemas/Shop"},

            item: {
              oneOf: [{
                "$ref": "#/components/schemas/Model"
              }, {
                "$ref": "#/components/schemas/Component"
              }, {
                "$ref": "#/components/schemas/Commodity"
              }, {
                "$ref": "#/components/schemas/Equipment"
              }, {
                "$ref": "#/components/schemas/ModelModule"
              }, {
                "$ref": "#/components/schemas/ModelPaint"
              }]
            },

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"},

            # DEPRECATED

            storeImage: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageSmall: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageMedium: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageLarge: {type: :string, nullable: true, format: :uri, deprecated: true}
          },
          additionalProperties: false,
          required: %w[
            id name slug prices confirmed commodityItemType commodityItemId shop
            createdAt updatedAt
          ]
        })
      end
    end
  end
end
