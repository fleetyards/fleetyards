# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class OutfitCharacterFace
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            token: {type: :string},
            name: {type: :string},
            body: ::V1::Schemas::Enums::OutfitBodyEnum
          },
          additionalProperties: false,
          required: %w[id token name body]
        })
      end
    end
  end
end
