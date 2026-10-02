# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ShopItemQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            # Shop category ids: "Equipment.clothing", "Model".
            categoryIn: {type: :array, items: {type: :string}},
            s: ::V1::Schemas::Enums::ShopItemSortingEnum
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
