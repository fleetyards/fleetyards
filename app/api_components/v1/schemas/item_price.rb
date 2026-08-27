# frozen_string_literal: true

module V1
  module Schemas
    class ItemPrice
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          price: {type: :number},
          timeRange: ::Shared::V1::Schemas::Enums::ItemPriceTimeRangeEnum,
          priceType: ::Shared::V1::Schemas::Enums::ItemPriceTypeEnum,
          itemId: {type: :string, format: :uuid},
          itemType: ::Shared::V1::Schemas::Enums::ItemPriceItemTypeEnum,
          location: {type: :string},
          locationUrl: {type: :string, format: :uri},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id price priceType itemId itemType location createdAt updatedAt]
      })
    end
  end
end
