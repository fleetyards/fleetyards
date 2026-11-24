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
            },
            nameKeys: {
              type: :array,
              maxItems: 5000,
              description: "The localisation keys a translated game's global.ini writes a name for",
              items: {
                type: :object,
                properties: {
                  name: {type: :string, maxLength: 255},
                  keys: {
                    type: :array,
                    items: {type: :string, maxLength: 255},
                    maxItems: 100
                  }
                },
                additionalProperties: false,
                required: %w[name keys]
              }
            }
          },
          additionalProperties: false,
          required: %w[names]
        })
      end
    end
  end
end
