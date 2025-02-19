# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class VehicleQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              searchCont: {type: :string},
              idEq: {type: :string},
              idIn: {type: :array, items: {type: :string}},
              idNotIn: {type: :array, items: {type: :string}},
              nameCont: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              userUsernameIn: {type: :array, items: {type: :string}},
              modelSlugIn: {type: :array, items: {type: :string}},
              manufacturerIn: {type: :array, items: {type: :string}},
              modelIdEq: {type: :string},
              modelIdIn: {type: :array, items: {type: :string}},
              modelIdNotIn: {type: :array, items: {type: :string}},
              modelNameCont: {type: :string},
              modelNameIn: {type: :array, items: {type: :string}},
              modelProductionStatusIn: {type: :array, items: {type: :string}},
              modelSearchCont: {type: :string},
              loanerEq: {type: :boolean},
              wantedEq: {type: :boolean},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/VehicleSortEnum"}
              }, {
                "$ref": "#/components/schemas/VehicleSortEnum"
              }]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
