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
            nameOrSlugCont: {type: :string},
            currentVersion: {type: :boolean, default: true},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},
            slugIn: {type: :array, items: {type: :string}},
            equipmentTypeIn: {type: :array, items: {type: :string}},
            itemTypeIn: {type: :array, items: {type: :string}},
            subTypeIn: {type: :array, items: {type: :string}},
            weaponClassIn: {type: :array, items: {type: :string}},
            slotIn: {type: :array, items: {type: :string, enum: ::Equipment.slots.keys}},
            sizeIn: {type: :array, items: {type: :string}},
            gradeIn: {type: :array, items: {type: :string}},
            manufacturerSlugIn: {type: :array, items: {type: :string}},
            **::Equipment::SORTABLE_METRICS.to_h { |metric| [:"#{metric}Gteq", {type: :number}] },
            **::Equipment::SORTABLE_METRICS.to_h { |metric| [:"#{metric}Lteq", {type: :number}] },

            s: {type: :string, enum: ::Equipment::ALLOWED_SORTING_PARAMS},
            sorts: {type: :array, items: {type: :string, enum: ::Equipment::ALLOWED_SORTING_PARAMS}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
