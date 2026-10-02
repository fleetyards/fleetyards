# frozen_string_literal: true

module V1
  module Schemas
    class LocationShopItem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: [:string, :null]},
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          prices: {type: :array, items: ::V1::Schemas::LocationShopItemPrice}
        },
        additionalProperties: false,
        required: %w[id name slug itemType prices]
      })
    end
  end
end
