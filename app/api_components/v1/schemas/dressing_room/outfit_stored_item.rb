# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class OutfitStoredItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            holder: ::V1::Schemas::Enums::OutfitHolderEnum,
            quantity: {type: :integer},
            equipment: {"$ref": "#/components/schemas/Equipment"}
          },
          additionalProperties: false,
          required: %w[holder quantity equipment]
        })
      end
    end
  end
end
