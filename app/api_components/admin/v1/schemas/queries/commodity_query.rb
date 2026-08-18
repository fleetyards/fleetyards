# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class CommodityQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              commodityTypeCont: {type: :string},
              uexCodeCont: {type: :string},
              storeImageBlank: {type: :boolean},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},
              commodityTypeIn: {type: :array, items: {type: :string}},

              # Compared against the same cheapest-of-that-direction figure the
              # payload exposes as `buyPrice`/`sellPrice`.
              buyPriceGteq: {type: :number},
              buyPriceLteq: {type: :number},
              sellPriceGteq: {type: :number},
              sellPriceLteq: {type: :number},

              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/CommoditySortEnum"}
              }, {
                "$ref": "#/components/schemas/CommoditySortEnum"
              }]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
