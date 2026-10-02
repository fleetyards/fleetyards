# frozen_string_literal: true

module V1
  module Schemas
    class LocationShopItemPrice
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # Shop-perspective, as everywhere: `sell` is the shop selling it.
          priceType: ::Shared::V1::Schemas::Enums::ItemPriceTypeEnum,
          price: {type: :number},
          timeRange: {anyOf: [::Shared::V1::Schemas::Enums::ItemPriceTimeRangeEnum, {type: :null}]}
        },
        additionalProperties: false,
        required: %w[priceType price timeRange]
      })
    end
  end
end
