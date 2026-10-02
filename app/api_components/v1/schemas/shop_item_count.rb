# frozen_string_literal: true

module V1
  module Schemas
    class ShopItemCount
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          count: {type: :integer}
        },
        additionalProperties: false,
        required: %w[itemType count]
      })
    end
  end
end
