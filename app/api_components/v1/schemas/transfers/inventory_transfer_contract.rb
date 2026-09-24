# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # The contract a shipment was sent towards. Null on an ordinary transfer,
      # which is the common case -- only a transfer carrying this link counts
      # towards a contract's progress.
      class InventoryTransferContract
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            slug: {type: :string},
            # The contract lives under its fleet, so a link needs both.
            fleetSlug: {type: :string},
            # The author's inventory the contract delivers into, when it is
            # one. Accepting there is what makes the delivery count.
            destinationInventoryId: {type: [:string, :null], format: :uuid}
          },
          additionalProperties: false,
          required: %w[id title slug fleetSlug destinationInventoryId]
        })
      end
    end
  end
end
