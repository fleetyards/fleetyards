# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class TradeRouteQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            commodityIdIn: {type: :array, items: {type: :string, format: :uuid}},
            commoditySlugIn: {type: :array, items: {type: :string}},
            originTerminalIdIn: {type: :array, items: {type: :string, format: :uuid}},
            destinationTerminalIdIn: {type: :array, items: {type: :string, format: :uuid}},
            originTerminalStarSystemIn: {type: :array, items: {type: :string}},
            destinationTerminalStarSystemIn: {type: :array, items: {type: :string}},

            # The ship to rank for. Without it the list ranks by profit per SCU
            # and the per-run figures stay null.
            modelSlug: {type: :string},

            # aUEC the pilot can spend. Caps the load at what it buys; only
            # read with a ship.
            budget: {type: :number, minimum: 0},

            # Leaves out routes where either price is older than this.
            maxPriceAgeHours: {type: :integer, minimum: 1},

            # One row per commodity and buy terminal, its best destination by
            # the requested sort.
            grouped: {type: :boolean},

            s: ::V1::Schemas::Enums::TradeRouteSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::TradeRouteSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
