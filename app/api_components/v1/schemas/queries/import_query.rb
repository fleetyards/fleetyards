# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ImportQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            typeEq: ::V1::Schemas::Enums::ImportTypeEnum,
            aasmStateEq: ::V1::Schemas::Enums::ImportStatusEnum,
            s: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::ImportSortEnum
            }, ::V1::Schemas::Sorts::ImportSortEnum]},
            sorts: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::ImportSortEnum
            }, ::V1::Schemas::Sorts::ImportSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
