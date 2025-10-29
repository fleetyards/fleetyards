# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ItemPriceQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              locationCont: {type: :string},
              itemIdEq: {type: :string, format: :uuid},
              itemIdIn: {type: :array, items: {type: :string, format: :uuid}},
              itemTypeEq: {"$ref": "#/components/schemas/ItemPriceItemTypeEnum"},
              itemTypeIn: {type: :array, items: {"$ref": "#/components/schemas/ItemPriceItemTypeEnum"}},
              priceTypeEq: {"$ref": "#/components/schemas/ItemPriceTypeEnum"},
              priceTypeIn: {type: :array, items: {"$ref": "#/components/schemas/ItemPriceTypeEnum"}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
