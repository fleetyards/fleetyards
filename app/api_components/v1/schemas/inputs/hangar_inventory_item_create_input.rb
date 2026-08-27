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
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            quantity: {type: :number},
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            entryType: ::V1::Schemas::Enums::InventoryEntryTypeEnum,
            quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
            image: {type: [:string, :null]},
            notes: {type: [:string, :null]},
            itemType: ::V1::Schemas::Enums::NullableInventoryItemTypeEnum,
            itemId: {type: [:string, :null], format: :uuid}
          },
          required: %w[name quantity],
          additionalProperties: false
        })
      end
    end
  end
end
