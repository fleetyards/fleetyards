# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarInventoryItemUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            notes: {type: [:string, :null]},
            category: {"$ref": "#/components/schemas/InventoryCategoryEnum"},
            unit: {"$ref": "#/components/schemas/InventoryUnitEnum"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
