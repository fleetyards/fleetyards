# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OutfitStoredItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            holder: ::V1::Schemas::Enums::OutfitHolderEnum,
            equipmentId: {type: :string, format: :uuid},
            quantity: {type: :integer, minimum: 1, maximum: ::OutfitStoredItem::MAX_QUANTITY}
          },
          required: %w[holder equipmentId quantity],
          additionalProperties: false
        })
      end
    end
  end
end
