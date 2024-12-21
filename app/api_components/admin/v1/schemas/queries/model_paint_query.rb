# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelPaintQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              nameEq: {type: :string},
              nameCont: {type: :string},
              idEq: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              idIn: {type: :array, items: {type: :string}},
              idNotIn: {type: :array, items: {type: :string}},
              modelSlugIn: {type: :array, items: {type: :string}},
              modelSlugEq: {type: :string},
              sorts: {oneOf: [{
                type: :array, items: {"$ref": "#/components/schemas/ModelPaintSortEnum"}
              }, {
                "$ref": "#/components/schemas/ModelPaintSortEnum"
              }]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
