# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        # One member's share of a stock row. A null holder is the share nobody
        # has been named for.
        class FleetInventoryStockHolder
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              holder: {
                anyOf: [::Shared::V1::Schemas::UserRefRequired, {type: :null}]
              },
              netQuantity: {type: :number}
            },
            additionalProperties: false,
            required: %w[holder netQuantity]
          })
        end
      end
    end
  end
end
