# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelPaintQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelIdEq: {type: :string, format: :uuid},
              nameEq: {type: :string},
              nameCont: {type: :string},
              idEq: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              idIn: {type: :array, items: {type: :string}},
              idNotIn: {type: :array, items: {type: :string}},
              modelSlugIn: {type: :array, items: {type: :string}},
              modelSlugEq: {type: :string},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/ModelPaintSortEnum"}
              }, {
                "$ref": "#/components/schemas/ModelPaintSortEnum"
              }]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
