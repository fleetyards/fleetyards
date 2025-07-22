# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ItemPriceInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              itemId: {type: :string, format: :uuid},
              itemType: {"$ref": "#/components/schemas/ItemPriceItemTypeEnum"},
              price: {type: :number},
              priceType: {"$ref": "#/components/schemas/ItemPriceTypeEnum"},
              location: {type: :string},
              locationUrl: {type: :string, format: :uri}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
