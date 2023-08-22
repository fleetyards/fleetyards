# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ModelPaintQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            idEq: {type: :string, format: :uuid},
            modelSlugEq: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            idNotIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
