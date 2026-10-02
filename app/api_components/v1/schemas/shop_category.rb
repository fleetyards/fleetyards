# frozen_string_literal: true

module V1
  module Schemas
    # One kind of thing a shop sells: "Clothing", "Coolers". A ship, paint or
    # commodity has no finer kind than its item type, so its key and label
    # are null.
    class ShopCategory
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          key: {type: [:string, :null]},
          label: {type: [:string, :null]},
          count: {type: :integer}
        },
        additionalProperties: false,
        required: %w[itemType key label count]
      })
    end
  end
end
