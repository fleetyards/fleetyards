# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelModulePackageQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              idEq: {type: :string, format: :uuid},
              nameCont: {type: :string},
              nameEq: {type: :string},
              modelIdEq: {type: :string, format: :uuid},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/ModelModulePackageSortEnum"}
              }, {
                "$ref": "#/components/schemas/ModelModulePackageSortEnum"
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
