# frozen_string_literal: true

module V1
  module Schemas
    class InventoryStockPosition
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          slug: {type: :string},
          name: {type: :string},
          category: ::V1::Schemas::Enums::InventoryCategoryEnum,
          unit: ::V1::Schemas::Enums::InventoryUnitEnum,
          netQuantity: {type: :number},
          qualityMin: {type: [:integer, :null]},
          qualityMax: {type: [:integer, :null]},
          entriesCount: {type: :integer},
          lastEntryAt: {type: [:string, :null], format: "date-time"},
          image: ::Shared::V1::Schemas::MediaFile,
          item: {
            type: [:object, :null],
            properties: {
              id: {type: :string, format: :uuid},
              type: ::V1::Schemas::Enums::InventoryItemTypeEnum,
              name: {type: :string},
              slug: {type: :string},
              available: {type: :boolean}
            }
          },
          inventory: ::V1::Schemas::InventoryRef
        },
        additionalProperties: false,
        required: %w[slug name category unit netQuantity entriesCount]
      })
    end
  end
end
