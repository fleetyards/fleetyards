# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class StationQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            searchCont: {type: :string, nullable: true},
            nameCont: {type: :string, nullable: true},
            slugEq: {type: :string, nullable: true},
            celestialObjectEq: {type: :string, nullable: true},
            cargoHubEq: {type: :boolean, nullable: true},
            refineryEq: {type: :boolean, nullable: true},
            withShops: {type: :boolean, nullable: true},
            habsNotNull: {type: :boolean, nullable: true},
            commodityItemType: {type: :string, nullable: true},
            nameIn: {type: :array, items: {type: :string}, nullable: true},
            celestialObjectIn: {type: :array, items: {type: :string}, nullable: true},
            starsystemIn: {type: :array, items: {type: :string}, nullable: true},
            stationTypeIn: {type: :array, items: {type: :string}, nullable: true},
            shopsShopTypeIn: {type: :array, items: {type: :string}, nullable: true},
            docksShipSizeIn: {type: :array, items: {type: :string}, nullable: true},
            sorts: {type: :array, items: {type: :string}, nullable: true}
          }
        })
      end
    end
  end
end
