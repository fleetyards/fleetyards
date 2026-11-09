# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyLight
        include OpenapiRuby::Components::Base

        vector = ->(size) { {type: :array, items: {type: :number}, minItems: size, maxItems: size} }

        schema({
          type: :object,
          properties: {
            type: {type: :string, enum: %w[spot point]},
            position: vector.call(3),
            direction: vector.call(3),
            color: vector.call(3).merge(description: "Linear RGB"),
            intensity: {type: :number, description: "three.js candela"},
            range: {type: :number},
            decay: {type: :number},
            angle: {type: :number, description: "A spot's outer cone angle, in radians"},
            penumbra: {type: :number},
            castShadow: {type: :boolean, description: "A soft (VSM) shadow, set by the studio's key light"}
          },
          additionalProperties: false,
          required: %w[type position color intensity]
        })
      end
    end
  end
end
