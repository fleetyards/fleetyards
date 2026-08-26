# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarInventoryItemCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            category: {"$ref": "#/components/schemas/InventoryCategoryEnum"},
            quantity: {type: :number},
            unit: {"$ref": "#/components/schemas/InventoryUnitEnum"},
            entryType: {"$ref": "#/components/schemas/InventoryEntryTypeEnum"},
            quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
            image: {type: [:string, :null]},
            notes: {type: [:string, :null]},
            itemType: {"$ref": "#/components/schemas/NullableInventoryItemTypeEnum"},
            itemId: {type: [:string, :null], format: :uuid}
          },
          required: %w[name quantity],
          additionalProperties: false
        })
      end
    end
  end
end
