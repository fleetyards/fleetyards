# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyHandBones
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            right: {type: :string},
            left: {type: :string}
          },
          additionalProperties: false,
          required: %w[right left]
        })
      end
    end
  end
end
