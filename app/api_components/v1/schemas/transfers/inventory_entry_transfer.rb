# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # Where a ledger entry's goods came from, or went to. Null on an entry
      # somebody typed, which is the distinction the ledger is there to make.
      class InventoryEntryTransfer
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            direction: ::V1::Schemas::Enums::InventoryEntryTransferDirectionEnum,
            counterparty: ::V1::Schemas::Transfers::TransferParty,
            inventory: ::V1::Schemas::Transfers::InventoryEntryTransferInventory
          },
          additionalProperties: false,
          required: %w[id direction]
        })
      end
    end
  end
end
