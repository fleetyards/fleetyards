# frozen_string_literal: true

module V1
  module Schemas
    module Commodities
      # One day of one commodity's prices, across every terminal that listed it.
      #
      # `sold` is the shop selling and `bought` the shop buying, the same
      # perspective `soldAt` and `boughtAt` use on the commodity itself. A day
      # nobody sold it has the `sold` figures null rather than zero.
      class CommodityPricePoint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            recordedOn: {type: :string, format: :date},
            soldLowest: {type: [:number, :null]},
            soldAverage: {type: [:number, :null]},
            soldHighest: {type: [:number, :null]},
            boughtLowest: {type: [:number, :null]},
            boughtAverage: {type: [:number, :null]},
            boughtHighest: {type: [:number, :null]}
          },
          required: %i[recordedOn],
          additionalProperties: false
        })
      end
    end
  end
end
