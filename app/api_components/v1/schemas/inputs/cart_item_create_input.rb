# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartItemCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            itemType: ::V1::Schemas::Enums::InventoryItemTypeEnum,
            itemId: {type: :string, format: :uuid},
            # Added to the quantity when the item is already in the cart.
            quantity: {type: :integer, minimum: 1},
            # Another of the user's lists; without it the item goes to the active one.
            cartId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[itemType itemId]
        })
      end
    end
  end
end
