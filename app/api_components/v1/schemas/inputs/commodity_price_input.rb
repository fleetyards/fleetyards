# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CommodityPriceInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            price: {type: :number},
            commodityItemId: {type: :string, format: :uuid},
            commodityItemType: {type: :string},
            path: {"$ref": "#/components/schemas/CommodityPricePathEnum"},
            shopId: {type: :string, format: :uuid},
            timeRange: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
