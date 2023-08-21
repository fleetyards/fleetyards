# frozen_string_literal: true

module Admin
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
              idEq: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              idIn: {type: :array, items: {type: :string}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
