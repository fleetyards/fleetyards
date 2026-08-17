# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class EquipmentQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              equipmentTypeCont: {type: :string},
              itemTypeCont: {type: :string},
              subTypeCont: {type: :string},
              weaponClassCont: {type: :string},
              hiddenEq: {type: :boolean},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},
              equipmentTypeIn: {type: :array, items: {type: :string}},
              itemTypeIn: {type: :array, items: {type: :string}},
              weaponClassIn: {type: :array, items: {type: :string}},
              slotIn: {type: :array, items: {type: :string, enum: ::Equipment.slots.keys}},
              manufacturerIdIn: {type: :array, items: {type: :string, format: :uuid}},

              # Compared against the same cheapest-of-that-direction figure the
              # payload exposes as `buyPrice`/`sellPrice`.
              buyPriceGteq: {type: :number},
              buyPriceLteq: {type: :number},
              sellPriceGteq: {type: :number},
              sellPriceLteq: {type: :number},

              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/EquipmentSortEnum"}
              }, {
                "$ref": "#/components/schemas/EquipmentSortEnum"
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
