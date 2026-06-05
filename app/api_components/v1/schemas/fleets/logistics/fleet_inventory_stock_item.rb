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
              name: {type: :string},
              category: {type: :string},
              unit: {type: :string},
              quality: {type: :integer},
              qualityMin: {type: :integer},
              qualityMax: {type: :integer},
              netQuantity: {type: :number},
              inventory: {
                type: :object,
                properties: {
                  name: {type: :string},
                  slug: {type: :string}
                }
              }
            },
            required: %w[name category unit netQuantity]
          })
        end
      end
    end
  end
end
