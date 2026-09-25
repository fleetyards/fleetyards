# frozen_string_literal: true

module V1
  module Schemas
    # The catalogue record a stock POSITION's entries point at, where every one
    # of them names the same one. A position's own name is whatever the owner
    # typed, so this is the only thing a caller can match a position on.
    #
    # Deliberately not `InventoryItemRef`, which is a ledger ENTRY's link: that
    # one always resolves and carries the record's name and availability, while
    # a position's is absent whenever its entries disagree or name nothing.
    class InventoryStockItemRef
      include OpenapiRuby::Components::Base

      schema({
        type: [:object, :null],
        properties: {
          id: {type: :string, format: :uuid},
          type: ::V1::Schemas::Enums::InventoryItemTypeEnum,
          slug: {type: [:string, :null]},
          # Whether the record has a public page to link to.
          listed: {type: :boolean}
        }
      })
    end
  end
end
