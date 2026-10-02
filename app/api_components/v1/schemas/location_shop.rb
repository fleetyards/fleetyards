# frozen_string_literal: true

module V1
  module Schemas
    class LocationShop
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          itemsCount: {type: :integer},
          items: {type: :array, items: ::V1::Schemas::LocationShopItem}
        },
        additionalProperties: false,
        required: %w[name itemsCount items]
      })
    end
  end
end
