# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ManufacturerQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            withModels: {type: :boolean},
            nameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
