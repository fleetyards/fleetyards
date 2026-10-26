# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      class Cart
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # The list these lines are on; null before the user has any.
            id: {type: [:string, :null], format: :uuid},
            name: {type: [:string, :null]},
            active: {type: :boolean},
            strategy: ::V1::Schemas::Enums::CartStrategyEnum,
            items: {type: :array, items: ::V1::Schemas::Carts::CartLine},
            # Only lines someone sells; the rest are counted in the totals.
            groups: {type: :array, items: ::V1::Schemas::Carts::CartGroup},
            totals: ::V1::Schemas::Carts::CartTotals
          },
          additionalProperties: false,
          required: %w[id name active strategy items groups totals]
        })
      end
    end
  end
end
