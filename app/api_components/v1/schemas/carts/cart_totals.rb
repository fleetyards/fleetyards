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
            itemsCount: {type: :integer},
            unavailableCount: {type: :integer},
            stopsCount: {type: :integer}
          },
          additionalProperties: false,
          required: %w[total itemsCount unavailableCount stopsCount]
        })
      end
    end
  end
end
