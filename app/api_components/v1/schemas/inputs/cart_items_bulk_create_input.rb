# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartItemsBulkCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              minItems: 1,
              maxItems: 500,
              items: ::V1::Schemas::Inputs::CartItemsBulkCreateItemInput
            },
            # Another of the user's lists; without it the items go to the active one.
            cartId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
