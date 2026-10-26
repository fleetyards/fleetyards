# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetShoppingListCopyInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # One of the user's own lists; without it a new list named after
            # the fleet's is started.
            cartId: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
