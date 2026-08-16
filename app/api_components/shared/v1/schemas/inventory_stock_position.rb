# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class InventoryStockPosition
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slug: {type: :string},
            name: {type: :string},
            category: {type: :string, enum: InventoryLedgerEntry::CATEGORIES.keys.map(&:to_s)},
            unit: {type: :string, enum: InventoryLedgerEntry::UNITS.keys.map(&:to_s)},
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
                type: {type: :string, enum: InventoryLedgerEntry::ITEM_TYPES},
                name: {type: :string},
                slug: {type: :string},
                available: {type: :boolean}
              }
            },
            inventory: {
              type: :object,
              properties: {
                name: {type: :string},
                slug: {type: :string}
              }
            }
          },
          additionalProperties: false,
          required: %w[slug name category unit netQuantity entriesCount]
        })
      end
    end
  end
end
