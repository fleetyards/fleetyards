# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Something in one of the reader's fleets' stores changed.
      #
      # The fleet is named as well as the inventory: a reader in three fleets
      # holds one subscription for all of them, so a logistics page open on one
      # fleet needs to know whether the ping is its own.
      class FleetInventoryChangedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            inventoryId: {type: :string, format: :uuid},
            inventorySlug: {type: :string},
            fleetSlug: {type: :string}
          },
          additionalProperties: false,
          required: %w[inventoryId inventorySlug fleetSlug]
        })
      end
    end
  end
end
