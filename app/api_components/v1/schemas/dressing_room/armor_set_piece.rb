# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class ArmorSetPiece
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slot: ::V1::Schemas::Enums::OutfitSlotEnum,
            slug: {type: :string},
            name: {type: :string}
          },
          additionalProperties: false,
          required: %w[slot slug name]
        })
      end
    end
  end
end
