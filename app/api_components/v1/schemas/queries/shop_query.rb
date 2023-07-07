# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ShopQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            searchCont: {type: :string, nullable: true},
            nameCont: {type: :string, nullable: true},
            commodityNameCont: {type: :string, nullable: true},
            nameIn: {type: :array, items: {type: :string}, nullable: true},
            modelIn: {type: :array, items: {type: :string}, nullable: true},
            equipmentIn: {type: :array, items: {type: :string}, nullable: true},
            componentIn: {type: :array, items: {type: :string}, nullable: true},
            commodityIn: {type: :array, items: {type: :string}, nullable: true},
            shop_typeIn: {type: :array, items: {type: :string}, nullable: true},
            commodityCategoryIn: {type: :array, items: {type: :string}, nullable: true},
            stationIn: {type: :array, items: {type: :string}, nullable: true},
            celestialObjectIn: {type: :array, items: {type: :string}, nullable: true},
            starsystemIn: {type: :array, items: {type: :string}, nullable: true}
          }
        })
      end
    end
  end
end
