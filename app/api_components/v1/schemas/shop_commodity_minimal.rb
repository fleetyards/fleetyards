# frozen_string_literal: true

module V1
  module Schemas
    class ShopCommodityMinimal < ShopCommodityBase
      include SchemaConcern

      schema({
        properties: {
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[createdAt updatedAt]
      })
    end
  end
end
