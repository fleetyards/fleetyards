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
              quality: {type: :integer, nullable: true},
              qualityMin: {type: :integer, nullable: true},
              qualityMax: {type: :integer, nullable: true},
              netQuantity: {type: :number},
              inventory: {
                type: :object,
                nullable: true,
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
