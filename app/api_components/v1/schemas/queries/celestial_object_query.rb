# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class CelestialObjectQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            starsystemEq: {type: :string},
            nameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            searchCont: {type: :string},
            parentEq: {type: :string},
            parentIdNull: {type: :boolean},
            main: {type: :boolean, deprecated: true},
            sorts: {oneOf: [{
              type: :array, items: {"$ref": "#/components/schemas/CelestialObjectSortEnum"}
            }, {
              "$ref": "#/components/schemas/CelestialObjectSortEnum"
            }]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
