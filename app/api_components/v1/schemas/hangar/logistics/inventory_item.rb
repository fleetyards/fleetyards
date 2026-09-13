# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        # Holder-neutral ledger entry. Renders from the same jbuilder as
        # HangarInventoryItem, so the two shapes cannot drift apart.
        class InventoryItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              positionId: {type: [:string, :null], format: :uuid},
              stockSlug: {type: :string},
              category: {type: :string},
              quantity: {type: :number},
              unit: {type: :string},
              entryType: ::V1::Schemas::Enums::InventoryEntryTypeEnum,
              quality: {type: :integer, minimum: 0, maximum: 1000},
              notes: {type: :string},
              transferId: {type: [:string, :null], format: :uuid},
              transfer: {
                type: [:object, :null],
                properties: {
                  id: {type: :string, format: :uuid},
                  direction: {type: :string, enum: %w[in out]},
                  counterparty: ::V1::Schemas::Transfers::TransferParty,
                  inventory: {
                    type: [:object, :null],
                    properties: {
                      name: {type: :string},
                      kind: ::V1::Schemas::Enums::InventoryTransferPartyKindEnum
                    }
                  }
                }
              },
              image: ::Shared::V1::Schemas::MediaFile,
              item: ::V1::Schemas::InventoryItemRef,
              inventory: ::V1::Schemas::InventoryRef,
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name category quantity unit entryType createdAt updatedAt]
          })
        end
      end
    end
  end
end
