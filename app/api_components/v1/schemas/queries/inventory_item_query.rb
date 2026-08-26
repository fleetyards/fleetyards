# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class InventoryItemQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            nameEq: {type: :string},
            unitEq: {"$ref": "#/components/schemas/InventoryUnitEnum"},
            categoryEq: {"$ref": "#/components/schemas/InventoryCategoryEnum"},
            qualityGteq: {type: :integer},
            qualityLteq: {type: :integer},
            sorts: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
