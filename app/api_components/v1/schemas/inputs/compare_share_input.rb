# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CompareShareInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          required: [:models],
          properties: {
            models: {
              type: :array,
              minItems: 1,
              maxItems: 8,
              items: {type: :string},
              description: "Model slugs (canonical or legacy) to include in the share link"
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
