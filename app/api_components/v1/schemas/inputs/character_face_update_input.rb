# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CharacterFaceUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, maxLength: 100}
          },
          required: %w[name],
          additionalProperties: false
        })
      end
    end
  end
end
