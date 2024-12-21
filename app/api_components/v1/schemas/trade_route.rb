# frozen_string_literal: true

module V1
  module Schemas
    class TradeRoute
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          origin: {"$ref": "#/components/schemas/TradeRouteLeg"},
          destination: {"$ref": "#/components/schemas/TradeRouteLeg"},
          commodity: {"$ref": "#/components/schemas/TradeRouteCommodity"},
          buyPrice: {type: :number},
          averageBuyPrice: {type: :number},
          sellPrice: {type: :number},
          averageSellPrice: {type: :number},
          profitPerUnit: {type: :number},
          averageProfitPerUnit: {type: :number},
          profitPerUnitPercent: {type: :number},
          averageProfitPerUnitPercent: {type: :number},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id createdAt updatedAt]
      })
    end
  end
end
