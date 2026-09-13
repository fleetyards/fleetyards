# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # The far inventory, as named on a ledger entry. Null while a transfer is
      # still waiting: the recipient has not chosen one yet.
      class InventoryEntryTransferInventory
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            name: {type: :string},
            kind: ::V1::Schemas::Enums::InventoryTransferPartyKindEnum
          },
          additionalProperties: false,
          required: %w[name kind]
        })
      end
    end
  end
end
