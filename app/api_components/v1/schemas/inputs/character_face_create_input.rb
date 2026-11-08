# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CharacterFaceCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            file: {type: :string, format: :binary, description: "The .chf the game's character creator exports"},
            name: {type: :string, maxLength: 100, description: "Defaults to the file's name"},
            body: ::V1::Schemas::Enums::OutfitBodyEnum
          },
          required: %w[file],
          additionalProperties: false
        })
      end
    end
  end
end
