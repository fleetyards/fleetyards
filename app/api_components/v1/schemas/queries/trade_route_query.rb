# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class TradeRouteQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            cargoShip: {type: :string},
            originStationIn: {type: :array, items: {type: :string}},
            destinationStationIn: {type: :array, items: {type: :string}},
            originCelestialObjectIn: {type: :array, items: {type: :string}},
            destinationCelestialObjectIn: {type: :array, items: {type: :string}},
            originStarsystemIn: {type: :array, items: {type: :string}},
            destinationStarsystemIn: {type: :array, items: {type: :string}},
            commodityIn: {type: :array, items: {type: :string}},
            commodityTypeIn: {type: :array, items: {"$ref": "#/components/schemas/CommodityTypeEnum"}},
            commodityTypeNotIn: {type: :array, items: {"$ref": "#/components/schemas/CommodityTypeEnum"}},
            sorts: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
