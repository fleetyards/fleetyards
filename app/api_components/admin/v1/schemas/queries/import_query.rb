# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ImportQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              typeEq: {"$ref": "#/components/schemas/ImportTypeEnum"},
              typeIn: {type: :array, items: {"$ref": "#/components/schemas/ImportTypeEnum"}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
