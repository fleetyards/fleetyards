# frozen_string_literal: true

module V1
  module Schemas
    # One thing a shop sells, rents or buys back, whatever catalogue it is
    # from, with the prices it has there.
    class ShopItem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          name: {type: :string},
          slug: {type: :string},
          # The shop category it is counted under, as `ShopCategory#id` names it.
          categoryId: {type: :string},
          categoryLabel: {type: [:string, :null]},
          manufacturer: {anyOf: [::Shared::V1::Schemas::ManufacturerLink, {type: :null}]},
          # What a reader pays, rents it for, and is paid for it here.
          buyPrice: {type: [:number, :null]},
          rentalPrice: {type: [:number, :null]},
          # The period the rental price is for, beside it.
          rentalTimeRange: ::Shared::V1::Schemas::Enums::NullableItemPriceTimeRangeEnum,
          sellPrice: {type: [:number, :null]}
        },
        additionalProperties: false,
        required: %w[id itemType name slug categoryId categoryLabel manufacturer buyPrice rentalPrice rentalTimeRange sellPrice]
      })
    end
  end
end
