# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class InventoryItemCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            quantity: {type: :number},
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            entryType: ::V1::Schemas::Enums::InventoryEntryTypeEnum,
            quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
            image: {type: [:string, :null]},
            notes: {type: [:string, :null]},
            itemType: ::V1::Schemas::Enums::NullableInventoryItemTypeEnum,
            itemId: {type: [:string, :null], format: :uuid},
            # A crafted part: the recipe it was made from, and the grade of material
            # in each of the recipe's graded slots, keyed by the slot's position.
            craftedBlueprintId: {type: [:string, :null], format: :uuid},
            craftedQualities: {
              type: [:object, :null],
              additionalProperties: {type: :integer, minimum: 0, maximum: 1000}
            }
          },
          required: %w[name quantity],
          additionalProperties: false
        })
      end
    end
  end
end
