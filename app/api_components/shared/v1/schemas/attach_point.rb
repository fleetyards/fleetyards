# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class AttachPoint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "A helper an item is hung by, in its holo's frame",
          properties: {
            position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
            rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"}
          },
          additionalProperties: false,
          required: %w[position rotation]
        })
      end
    end
  end
end
