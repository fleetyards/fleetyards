# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class EquipmentFacetFilterQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            equipmentTypeIn: {type: :array, items: {type: :string}},
            subTypeIn: {type: :array, items: {type: :string}},
            slotIn: {type: :array, items: ::V1::Schemas::Enums::EquipmentSlotEnum},
            sizeIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
