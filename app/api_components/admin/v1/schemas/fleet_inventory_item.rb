# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FleetInventoryItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fleetInventoryId: {type: :string, format: :uuid},
            name: {type: :string},
            category: ::Admin::V1::Schemas::Enums::InventoryCategoryEnum,
            entryType: ::Admin::V1::Schemas::Enums::InventoryEntryTypeEnum,
            unit: ::Admin::V1::Schemas::Enums::InventoryUnitEnum,
            quantity: {type: :string},
            quality: {type: [:integer, :null]},
            notes: {type: [:string, :null]},
            # The catalogue row this entry was filled from, when it was named
            # from one rather than typed in free-hand.
            itemId: {type: [:string, :null], format: :uuid},
            itemType: {type: [:string, :null]},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fleetInventoryId name category entryType unit quantity createdAt updatedAt]
        })
      end
    end
  end
end
