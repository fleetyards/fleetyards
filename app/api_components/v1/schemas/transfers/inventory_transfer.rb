# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      class InventoryTransfer
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            state: ::V1::Schemas::Enums::InventoryTransferStateEnum,
            note: {type: [:string, :null]},
            # False when somebody has to answer it. The client shows a
            # destination picker or a party picker on this rather than
            # reimplementing the rule that decides it.
            immediate: {type: :boolean},
            source: ::V1::Schemas::Transfers::InventoryTransferEndpoint,
            destination: ::V1::Schemas::Transfers::InventoryTransferEndpoint,
            sender: ::V1::Schemas::Transfers::TransferParty,
            recipient: ::V1::Schemas::Transfers::TransferParty,
            destinationParty: ::V1::Schemas::Transfers::TransferParty,
            initiatedBy: {type: [:string, :null]},
            resolvedBy: {type: [:string, :null]},
            lines: {
              type: :array,
              items: ::V1::Schemas::Transfers::InventoryTransferLine
            },
            expiresAt: {type: [:string, :null], format: "date-time"},
            completedAt: {type: [:string, :null], format: "date-time"},
            declinedAt: {type: [:string, :null], format: "date-time"},
            cancelledAt: {type: [:string, :null], format: "date-time"},
            expiredAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: [:string, :null], format: "date-time"},
            updatedAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id state immediate source destination sender recipient lines]
        })
      end
    end
  end
end
