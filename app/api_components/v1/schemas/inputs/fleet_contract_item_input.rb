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
            quality: {type: [:integer, :null]},
            qualityMatch: ::V1::Schemas::Enums::FleetContractQualityMatchEnum,
            position: {type: :integer},
            itemType: ::V1::Schemas::Enums::NullableInventoryItemTypeEnum,
            itemId: {type: [:string, :null], format: :uuid},
            # A crafted part: the recipe, and the grades asked for per slot,
            # keyed by the slot's position. A slot left out takes any grade.
            craftedBlueprintId: {type: [:string, :null], format: :uuid},
            craftedQualities: {
              type: [:object, :null],
              additionalProperties: {type: :integer, minimum: 0, maximum: 1000}
            }
          },
          additionalProperties: false,
          required: %w[name category unit quantity]
        })
      end
    end
  end
end
