# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyClip
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, description: "The clip's name in the body's animations file"},
            static: {type: :boolean, description: "A single-frame pose rather than a motion"},
            looping: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[name static looping]
        })
      end
    end
  end
end
