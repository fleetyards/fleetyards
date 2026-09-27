# frozen_string_literal: true

module V1
  module Schemas
    class TradeRoute
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          commodity: ::Shared::V1::Schemas::CommodityRef,
          originTerminal: ::V1::Schemas::Terminal,
          destinationTerminal: ::V1::Schemas::Terminal,

          # What the player pays at the origin and is paid at the destination,
          # per SCU.
          priceOrigin: {type: :number},
          priceDestination: {type: :number},
          profitPerScu: {type: :number},

          # Stock at the origin and demand at the destination, in SCU.
          scuOrigin: {type: :integer},
          scuDestination: {type: :integer},

          # The crate sizes both terminals and the commodity allow, in SCU.
          containerSizes: {type: :array, items: {type: :integer}},
          distance: {type: [:number, :null]},
          originPriceUpdatedAt: {type: [:string, :null], format: "date-time"},
          destinationPriceUpdatedAt: {type: [:string, :null], format: "date-time"},

          # For the ship in the query, null without one: what fits in its holds
          # in the allowed crate sizes, capped by stock and demand, and what a
          # run of that load costs and earns. A zero distance leaves the profit
          # per distance null rather than infinite.
          loadableScu: {type: [:integer, :null]},
          loadLimit: ::V1::Schemas::Enums::NullableTradeRouteLoadLimitEnum,

          # Set when the chosen ship can't land on a planet and an end of the
          # run is on one. The figures stay, so the run can still be shown.
          unflyableReason: ::V1::Schemas::Enums::NullableTradeRouteUnflyableReasonEnum,

          # In a grouped list, how many other terminals buy this commodity from
          # the same origin. Null in an ungrouped one.
          otherDestinations: {type: [:integer, :null]},
          investment: {type: [:number, :null]},
          profitPerRun: {type: [:number, :null]},
          profitPerDistance: {type: [:number, :null]}
        },
        additionalProperties: false,
        required: %w[
          id commodity originTerminal destinationTerminal priceOrigin priceDestination profitPerScu
          scuOrigin scuDestination containerSizes
        ]
      })
    end
  end
end
