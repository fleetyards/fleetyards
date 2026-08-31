# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarInventoryItemQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            nameEq: {type: :string},
            unitEq: ::V1::Schemas::Enums::InventoryUnitEnum,
            categoryEq: ::V1::Schemas::Enums::InventoryCategoryEnum,
            qualityGteq: {type: :integer},
            qualityLteq: {type: :integer},
            s: {type: :string},
            sorts: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
