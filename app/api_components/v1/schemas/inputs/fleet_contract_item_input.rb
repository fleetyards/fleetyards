# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetContractItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            quantity: {type: :string},
            # Only meaningful on a crafting contract; ignored elsewhere.
            minQuality: {type: [:integer, :null]},
            position: {type: :integer},
            itemType: ::V1::Schemas::Enums::NullableInventoryItemTypeEnum,
            itemId: {type: [:string, :null], format: :uuid}
          },
          additionalProperties: false,
          required: %w[name category unit quantity]
        })
      end
    end
  end
end
