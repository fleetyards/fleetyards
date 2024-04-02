# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class CommodityPrice
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            price: {type: :number},
            timeRange: {type: :string},
            confirmed: {type: :boolean},
            type: {type: :string},
            submitters: {type: :array, items: {type: :string, format: :uuid}},
            shopCommodity: {"$ref": "#/components/schemas/ShopCommodity"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id price confirmed type submitters createdAt updatedAt]
        })
      end
    end
  end
end
