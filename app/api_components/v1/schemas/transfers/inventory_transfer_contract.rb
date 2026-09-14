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
            fleetSlug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id title slug fleetSlug]
        })
      end
    end
  end
end
