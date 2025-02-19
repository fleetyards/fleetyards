# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              idEq: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              idIn: {type: :array, items: {type: :string}},
              idNotIn: {type: :array, items: {type: :string}},
              manufacturerIn: {type: :array, items: {type: :string}},
              productionStatusIn: {type: :array, items: {type: :string}},
              searchCont: {type: :string},
              scIdentifierBlank: {type: :boolean},
              fleetchartImageBlank: {type: :boolean},
              holoBlank: {type: :boolean},
              topViewColoredBlank: {type: :boolean},
              frontViewBlank: {type: :boolean},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/ModelSortEnum"}
              }, {
                "$ref": "#/components/schemas/ModelSortEnum"
              }]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
