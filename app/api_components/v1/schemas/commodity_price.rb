# frozen_string_literal: true

module V1
  module Schemas
    class CommodityPrice
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          price: {type: :number, format: :float},
          timeRange: {type: :string, nullable: true},
          type: {type: :string},
          shopCommodityId: {type: :string, format: :uuid},
          confirmed: {type: :boolean},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[id price type shopCommodityId confirmed createdAt updatedAt]
      })
    end
  end
end
