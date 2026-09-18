# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventoryStockItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slug: {type: :string},
              name: {type: :string},
              category: {type: :string},
              unit: {type: :string},
              quality: {type: :integer},
              qualityMin: {type: :integer},
              qualityMax: {type: :integer},
              netQuantity: {type: :number},

              # The catalogue record the position's entries point at, where
              # they agree on one. A position's own name is whatever the
              # owner typed, so this is the only thing a caller can match on.
              item: {
                type: [:object, :null],
                properties: {
                  id: {type: :string, format: :uuid},
                  type: ::V1::Schemas::Enums::InventoryItemTypeEnum
                }
              },
              inventory: ::V1::Schemas::InventoryRef
            },
            required: %w[id name category unit netQuantity]
          })
        end
      end
    end
  end
end
