# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class CommodityPriceInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              shopCommodityId: {type: :string, format: :uuid},
              price: {type: :number},
              timeRange: {"$ref": "#/components/schemas/CommodityPriceTimeRangeEnum"},
              path: {"$ref": "#/components/schemas/CommodityPricePathEnum"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
