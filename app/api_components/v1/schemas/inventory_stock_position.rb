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
          category: {"$ref": "#/components/schemas/InventoryCategoryEnum"},
          unit: {"$ref": "#/components/schemas/InventoryUnitEnum"},
          netQuantity: {type: :number},
          qualityMin: {type: [:integer, :null]},
          qualityMax: {type: [:integer, :null]},
          entriesCount: {type: :integer},
          lastEntryAt: {type: [:string, :null], format: "date-time"},
          image: {"$ref": "#/components/schemas/MediaFile"},
          item: {
            type: [:object, :null],
            properties: {
              id: {type: :string, format: :uuid},
              type: {"$ref": "#/components/schemas/InventoryItemTypeEnum"},
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
