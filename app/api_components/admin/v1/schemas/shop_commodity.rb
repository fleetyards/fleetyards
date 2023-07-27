# frozen_string_literal: true

module Admin
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
              }
            },
            category: {"$ref": "#/components/schemas/ShopCommodityCategoryEnum"},
            subCategory: {
              oneOf: [{
                "$ref": "#/components/schemas/ModelClassificationEnum"
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
              required: %w[pricePerUnit]
            },

            locationLabel: {type: :string, nullable: true},
            confirmed: {type: :boolean},

            commodityItemType: {"$ref": "#/components/schemas/ShopCommodityItemTypeEnum"},
            commodityItemId: {type: :string, format: :uuid},

            shop: {"$ref": "#/components/schemas/Shop"}
          },
          additionalProperties: false,
          required: %w[id name slug prices confirmed commodityItemType commodityItemId shop]
        })
      end
    end
  end
end
