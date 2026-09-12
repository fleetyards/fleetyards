# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Where it lands. Chosen by the receiving side, because the sender may not
      # be permitted to see their inventories -- and a ship's does not exist
      # until something is put in it, which `vehicleId` handles.
      class InventoryTransferAcceptInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            inventoryId: {type: :string, format: :uuid},
            fleetInventoryId: {type: :string, format: :uuid},
            vehicleId: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
