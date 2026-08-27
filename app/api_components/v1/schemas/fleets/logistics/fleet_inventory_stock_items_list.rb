# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventoryStockItemsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Fleets::Logistics::FleetInventoryStockItem
          })
        end
      end
    end
  end
end
