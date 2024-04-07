# frozen_string_literal: true

module V1
  module Schemas
    class ItemPrice
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          price: {type: :number},
          timeRange: {"$ref": "#/components/schemas/ItemPriceTimeRangeEnum"},
          priceType: {"$ref": "#/components/schemas/ItemPriceTypeEnum"},
          location: {type: :string},
          locationUrl: {type: :string, format: :uri},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id price priceType location createdAt updatedAt]
      })
    end
  end
end
