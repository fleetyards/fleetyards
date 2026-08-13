# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class InventoryStockPositionInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            category: {type: :string, enum: InventoryLedgerEntry::CATEGORIES.keys.map(&:to_s)},
            unit: {type: :string, enum: InventoryLedgerEntry::UNITS.keys.map(&:to_s)}
          },
          additionalProperties: false
        })
      end
    end
  end
end
