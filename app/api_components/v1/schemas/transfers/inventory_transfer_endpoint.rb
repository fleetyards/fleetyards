# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # One end of a transfer. Null while a pending transfer's destination is
      # still unchosen, and after an end was deleted once it had finished.
      class InventoryTransferEndpoint
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            kind: ::V1::Schemas::Enums::InventoryTransferPartyKindEnum
          },
          additionalProperties: false,
          required: %w[id name slug kind]
        })
      end
    end
  end
end
