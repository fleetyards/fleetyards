# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartItemUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            quantity: {type: :integer, minimum: 1},
            # One of the item's sell prices, or null to go back to the cheapest.
            itemPriceId: {type: [:string, :null], format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
