# frozen_string_literal: true

module V1
  module Schemas
    # One commodity with what only its page draws. Separate from the list shape:
    # the per-terminal prices were 539 rows on a page of 60, and the list only
    # states `buyPrice` and `sellPrice`.
    class CommodityDetail < ::V1::Schemas::Commodity
      include OpenapiRuby::Components::Base

      schema({
        properties: {
          # The raw forms that refine into this one, still in the build we are
          # on. Outside the cached fragment: its key is this row, and these are
          # other rows pointing at it.
          refinedFrom: {type: :array, items: ::Shared::V1::Schemas::CommodityRef},

          # The UEX snapshot prices commodities at every terminal that trades
          # them, which is the whole point of syncing it -- the same shape the
          # component and equipment payloads carry.
          availability: Shared::V1::Schemas::ItemAvailability
        },
        required: %w[refinedFrom availability]
      })
    end
  end
end
