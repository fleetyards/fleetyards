# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ShopQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            searchCont: {type: :string},
            nameCont: {type: :string},
            commodityNameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            modelIn: {type: :array, items: {type: :string}},
            equipmentIn: {type: :array, items: {type: :string}},
            componentIn: {type: :array, items: {type: :string}},
            commodityIn: {type: :array, items: {type: :string}},
            shop_typeIn: {type: :array, items: {type: :string}},
            commodityCategoryIn: {type: :array, items: {type: :string}},
            stationIn: {type: :array, items: {type: :string}},
            celestialObjectIn: {type: :array, items: {type: :string}},
            starsystemIn: {type: :array, items: {type: :string}}
          }
        })
      end
    end
  end
end
