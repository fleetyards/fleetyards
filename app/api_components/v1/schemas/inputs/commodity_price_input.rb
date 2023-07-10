# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CommodityPriceInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            commodityItemId: {type: :string, format: :uuid},
            commodityItemType: {type: :string},
            path: {type: :string, enum: %w[buy sell rental]},
            shopId: {type: :string, format: :uuid},
            timeRange: {type: :string, nullable: true}
          },
          additionalProperties: false,
          required: %w[commodityItemId commodityItemType path shopId]
        })
      end
    end
  end
end
