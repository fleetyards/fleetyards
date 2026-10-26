# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartItemsBulkCreateItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            itemType: ::V1::Schemas::Enums::InventoryItemTypeEnum,
            itemId: {type: :string, format: :uuid},
            quantity: {type: :integer, minimum: 1}
          },
          additionalProperties: false,
          required: %w[itemType itemId]
        })
      end
    end
  end
end
