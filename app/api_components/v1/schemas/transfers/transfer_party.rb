# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # A user or a fleet. Told apart by `kind` rather than by which key is
      # present, so a client never has to guess from the shape.
      class TransferParty
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            kind: ::V1::Schemas::Enums::InventoryTransferPartyKindEnum,
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[kind name slug]
        })
      end
    end
  end
end
