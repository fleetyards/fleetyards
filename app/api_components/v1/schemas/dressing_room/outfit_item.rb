# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class OutfitItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slot: ::V1::Schemas::Enums::OutfitSlotEnum,
            equipment: {"$ref": "#/components/schemas/Equipment"}
          },
          additionalProperties: false,
          required: %w[slot equipment]
        })
      end
    end
  end
end
