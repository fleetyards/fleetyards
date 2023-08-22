# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class StationQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            searchCont: {type: :string},
            nameCont: {type: :string},
            slugEq: {type: :string},
            celestialObjectEq: {type: :string},
            cargoHubEq: {type: :boolean},
            refineryEq: {type: :boolean},
            withShops: {type: :boolean},
            habsNotNull: {type: :boolean},
            commodityItemType: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            celestialObjectIn: {type: :array, items: {type: :string}},
            starsystemIn: {type: :array, items: {type: :string}},
            stationTypeIn: {type: :array, items: {type: :string}},
            shopsShopTypeIn: {type: :array, items: {type: :string}},
            docksShipSizeIn: {type: :array, items: {type: :string}},
            sorts: {oneOf: [{
              type: :array, items: {"$ref": "#/components/schemas/StationSortEnum"}
            }, {
              "$ref": "#/components/schemas/StationSortEnum"
            }]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
