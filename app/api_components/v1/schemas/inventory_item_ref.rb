# frozen_string_literal: true

module V1
  module Schemas
    # The catalogue record a ledger entry points at.
    class InventoryItemRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          type: ::V1::Schemas::Enums::InventoryItemTypeEnum,
          name: {type: :string},
          slug: {type: :string},
          # Whether the record has a public page to link to. False for a hidden
          # equipment variant, which the catalogue leaves out.
          listed: {type: :boolean},

          # Whether the game counts this one in pieces. The unit picker needs it
          # to know that `units` is on offer for a commodity at all.
          counted: {type: :boolean},
          available: {type: :boolean}
        }
      })
    end
  end
end
