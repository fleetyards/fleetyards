# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyEyes
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The customizer's white iris and the game's default iris colour, for a head drawn without a character file",
          properties: {
            iris: {type: :string, format: :uri},
            irisColor: {type: :string, pattern: "^#[0-9a-f]{6}$"}
          },
          additionalProperties: false,
          required: %w[iris irisColor]
        })
      end
    end
  end
end
