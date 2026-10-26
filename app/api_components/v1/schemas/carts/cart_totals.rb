# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      class CartTotals
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "Cart costs in aUEC, over the lines someone sells",
          properties: {
            total: {type: :number},
            # Lines on the list.
            itemsCount: {type: :integer},
            # What the lines add up to: four of one item count four.
            quantity: {type: :integer},
            unavailableCount: {type: :integer},
            stopsCount: {type: :integer}
          },
          additionalProperties: false,
          required: %w[total itemsCount quantity unavailableCount stopsCount]
        })
      end
    end
  end
end
