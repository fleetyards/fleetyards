# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CompareShareInput
        include OpenapiRuby::Components::Base

        # One kind per link: the controller answers 400 when more than one of
        # these is present.
        schema({
          type: :object,
          properties: {
            models: {
              type: :array,
              minItems: 1,
              maxItems: 8,
              items: {type: :string},
              description: "Model slugs (canonical or legacy) to include in the share link"
            },
            components: {
              type: :array,
              minItems: 1,
              maxItems: 8,
              items: {type: :string},
              description: "Component slugs to include in the share link"
            },
            equipment: {
              type: :array,
              minItems: 1,
              maxItems: 8,
              items: {type: :string},
              description: "Equipment slugs to include in the share link"
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
