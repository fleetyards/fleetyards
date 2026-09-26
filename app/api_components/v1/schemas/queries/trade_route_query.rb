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
