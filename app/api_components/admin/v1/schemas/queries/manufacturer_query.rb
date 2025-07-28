# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ManufacturerQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              withModels: {type: :boolean},
              logoBlank: {type: :boolean},
              nameEq: {type: :string},
              nameCont: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              slugEq: {type: :string},
              slugCont: {type: :string},
              slugIn: {type: :array, items: {type: :string}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
