# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ImportQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              typeEq: {"$ref": "#/components/schemas/ImportTypeEnum"},
              typeIn: {type: :array, items: {"$ref": "#/components/schemas/ImportTypeEnum"}},
              typeNotIn: {type: :array, items: {"$ref": "#/components/schemas/ImportTypeEnum"}},
              aasmStateEq: {"$ref": "#/components/schemas/ImportStatusEnum"},
              aasmStateIn: {type: :array, items: {"$ref": "#/components/schemas/ImportStatusEnum"}}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
