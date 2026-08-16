# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class EquipmentQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},
            slugIn: {type: :array, items: {type: :string}},
            equipmentTypeIn: {type: :array, items: {type: :string}},
            itemTypeIn: {type: :array, items: {type: :string}},
            manufacturerSlugIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
