# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Extends the shared component with what only an admin is shown. Named the
      # same so the admin document's `Component` resolves here while the public
      # one keeps the shared definition.
      class Component < ::Shared::V1::Schemas::Component
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            # The cheapest of `availability`, flattened out so the list can show
            # and filter by a price without reading down the terminal arrays.
            buyPrice: {type: [:number, :null]},
            sellPrice: {type: [:number, :null]}
          }
        })
      end
    end
  end
end
