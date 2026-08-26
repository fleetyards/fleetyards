# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventoryStockItemsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/FleetInventoryStockItem"}
          })
        end
      end
    end
  end
end
