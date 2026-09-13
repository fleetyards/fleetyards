# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      # One position of a shipment. These are ledger entries rather than rows of
      # a line table, so what is listed is exactly what left the source.
      class InventoryTransferLine
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            quantity: {type: :number},
            quality: {type: [:integer, :null]},
            positionId: {type: :string, format: :uuid},
            itemAvailable: {type: :boolean},
            image: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[id name category unit quantity positionId itemAvailable]
        })
      end
    end
  end
end
