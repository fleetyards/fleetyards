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
              slug: {type: :string},
              name: {type: :string},
              category: {type: :string},
              unit: {type: :string},
              quality: {type: :integer},
              qualityMin: {type: :integer},
              qualityMax: {type: :integer},
              netQuantity: {type: :number},
              inventory: Shared::V1::Schemas::InventoryRef
            },
            required: %w[name category unit netQuantity]
          })
        end
      end
    end
  end
end
