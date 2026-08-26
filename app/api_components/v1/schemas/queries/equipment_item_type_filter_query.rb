# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class EquipmentItemTypeFilterQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            equipmentTypeIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
