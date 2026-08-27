# frozen_string_literal: true

module V1
  module Schemas
    class InventoryStockPositionsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/InventoryStockPosition"}
      })
    end
  end
end
