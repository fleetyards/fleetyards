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
            main: {type: :boolean},
            nameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            searchCont: {type: :string}
          }
        })
      end
    end
  end
end
