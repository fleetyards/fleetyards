# frozen_string_literal: true

module V1
  module Schemas
    class ShopItem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: [:string, :null]},
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          # Finer than the kind, where it has one: "clothing", "cooler".
          category: {type: [:string, :null]},
          categoryLabel: {type: [:string, :null]},
          prices: {type: :array, items: ::V1::Schemas::ShopItemPrice}
        },
        additionalProperties: false,
        required: %w[id name slug itemType category categoryLabel prices]
      })
    end
  end
end
