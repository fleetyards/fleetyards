# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        # Holder-neutral ledger entry. Renders from the same jbuilder as
        # HangarInventoryItem, so the two shapes cannot drift apart.
        class InventoryItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              stockSlug: {type: :string},
              category: {type: :string},
              quantity: {type: :number},
              unit: {type: :string},
              entryType: {"$ref": "#/components/schemas/InventoryEntryTypeEnum"},
              quality: {type: :integer, minimum: 0, maximum: 1000},
              notes: {type: :string},
              image: {"$ref": "#/components/schemas/MediaFile"},
              item: Shared::V1::Schemas::InventoryItemRef,
              inventory: Shared::V1::Schemas::InventoryRef,
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name category quantity unit entryType createdAt updatedAt]
          })
        end
      end
    end
  end
end
