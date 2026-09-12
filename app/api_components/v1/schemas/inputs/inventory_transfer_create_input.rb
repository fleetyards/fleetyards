# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Some positions, some quantities, and a target.
      #
      # A target is exactly one of: an inventory (`inventoryId`,
      # `fleetInventoryId` or `vehicleId`), or a party to ask
      # (`recipientUsername`, `recipientFleetSlug`). Naming an inventory you may
      # not deposit into is refused rather than converted into a request --
      # otherwise the response would reveal that it exists.
      class InventoryTransferCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sourceInventoryId: {type: :string, format: :uuid},
            lines: {
              type: :array,
              minItems: 1,
              items: {
                type: :object,
                properties: {
                  positionId: {type: :string, format: :uuid},
                  quantity: {type: :number, exclusiveMinimum: 0}
                },
                additionalProperties: false,
                required: %w[positionId quantity]
              }
            },
            inventoryId: {type: :string, format: :uuid},
            fleetInventoryId: {type: :string, format: :uuid},
            vehicleId: {type: :string, format: :uuid},
            recipientUsername: {type: :string},
            recipientFleetSlug: {type: :string},
            note: {type: :string}
          },
          additionalProperties: false,
          required: %w[sourceInventoryId lines]
        })
      end
    end
  end
end
