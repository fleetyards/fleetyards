# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        class HangarInventoryStockItemsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Hangar::Logistics::HangarInventoryStockItem
          })
        end
      end
    end
  end
end
