# frozen_string_literal: true

module V1
  module Schemas
    class InventoryStockPosition
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
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
              # Whether the record has a public page to link to.
              listed: {type: :boolean},

              # Whether the game counts this one in pieces. Renaming a position
              # offers `units` only where the API would take it.
              counted: {type: :boolean},
              available: {type: :boolean}
            }
          },
          inventory: ::V1::Schemas::InventoryRef
        },
        additionalProperties: false,
        required: %w[id slug name category unit netQuantity entriesCount]
      })
    end
  end
end
