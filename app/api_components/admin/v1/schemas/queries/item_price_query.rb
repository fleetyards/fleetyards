# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ItemPriceQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              locationCont: {type: :string},
              itemIdEq: {type: :string, format: :uuid},
              itemIdIn: {type: :array, items: {type: :string, format: :uuid}},
              itemTypeEq: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
              itemTypeIn: {type: :array, items: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum},
              priceTypeEq: ::Shared::V1::Schemas::Enums::ItemPriceTypeEnum,
              priceTypeIn: {type: :array, items: ::Shared::V1::Schemas::Enums::ItemPriceTypeEnum}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
