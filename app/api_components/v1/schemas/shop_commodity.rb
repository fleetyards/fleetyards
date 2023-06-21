# frozen_string_literal: true

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
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
            }
          },
          category: {type: :string, nullable: true},
          subCategory: {type: :string, nullable: true},
          subCategoryLabel: {type: :string, nullable: true},

          prices: {
            type: :object,
            properties: {
              averageBuyPrice: {type: :number, nullable: true},
              averageRentalPrice1Day: {type: :number, nullable: true},
              averageRentalPrice30Days: {type: :number, nullable: true},
              averageRentalPrice3Days: {type: :number, nullable: true},
              averageRentalPrice7Days: {type: :number, nullable: true},
              averageSellPrice: {type: :number, nullable: true},
              buyPrice: {type: :number, nullable: true},
              rentalPrice1Day: {type: :number, nullable: true},
              rentalPrice30Days: {type: :number, nullable: true},
              rentalPrice3Days: {type: :number, nullable: true},
              rentalPrice7Days: {type: :number, nullable: true},
              sellPrice: {type: :number, nullable: true}
            }
          },
          pricePerUnit: {type: :boolean},

          locationLabel: {type: :string, nullable: true},
          confirmed: {type: :boolean},

          commodityItemType: {type: :string},
          commodityItemId: {type: :string, format: :uuid},

          shop: {"$ref": "#/components/schemas/Shop"},

          storeImage: {type: :string, nullable: true, format: :uri, deprecated: true},
          storeImageSmall: {type: :string, nullable: true, format: :uri, deprecated: true},
          storeImageMedium: {type: :string, nullable: true, format: :uri, deprecated: true},
          storeImageLarge: {type: :string, nullable: true, format: :uri, deprecated: true}
        },
        required: %w[id name slug media prices pricePerUnit confirmed commodityItemType commodityItemId shop]
      })
    end
  end
end
