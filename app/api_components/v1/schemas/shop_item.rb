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
          manufacturer: {
            anyOf: [
              {
                type: :object,
                properties: {name: {type: :string}, slug: {type: :string}},
                additionalProperties: false,
                required: %w[name slug]
              },
              {type: :null}
            ]
          },
          # What a reader pays, rents it for, and is paid for it here.
          buyPrice: {type: [:number, :null]},
          rentalPrice: {type: [:number, :null]},
          sellPrice: {type: [:number, :null]}
        },
        additionalProperties: false,
        required: %w[id itemType name slug categoryId categoryLabel manufacturer buyPrice rentalPrice sellPrice]
      })
    end
  end
end
