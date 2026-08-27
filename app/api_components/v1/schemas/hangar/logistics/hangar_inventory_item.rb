# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        class HangarInventoryItem
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
              entryType: ::V1::Schemas::Enums::InventoryEntryTypeEnum,
              quality: {type: :integer, minimum: 0, maximum: 1000},
              notes: {type: :string},
              image: ::Shared::V1::Schemas::MediaFile,
              item: ::V1::Schemas::InventoryItemRef,
              inventory: ::V1::Schemas::InventoryRef,
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
