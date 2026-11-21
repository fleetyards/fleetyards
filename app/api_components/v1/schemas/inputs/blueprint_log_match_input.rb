# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class BlueprintLogMatchInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            names: {
              type: :array,
              items: {type: :string, maxLength: 255},
              maxItems: 5000,
              description: "Blueprint names as the game log's \"Received Blueprint\" notifications spell them"
            }
          },
          additionalProperties: false,
          required: %w[names]
        })
      end
    end
  end
end
