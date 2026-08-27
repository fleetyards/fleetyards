# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ItemPriceInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              itemId: {type: :string, format: :uuid},
              itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
              price: {type: :number},
              priceType: ::Shared::V1::Schemas::Enums::ItemPriceTypeEnum,
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
