# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # One position of a shipment, and how much of it is moving.
      #
      # Quantity defaults to the whole position in the interface; a part of one
      # is the exception. `exclusiveMinimum` matches the builder, which refuses
      # a zero or negative line — and refuses the whole shipment with it, since
      # a transfer is all-or-nothing.
      class InventoryTransferLineInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            positionId: {type: :string, format: :uuid},
            quantity: {type: :number, exclusiveMinimum: 0}
          },
          additionalProperties: false,
          required: %w[positionId quantity]
        })
      end
    end
  end
end
