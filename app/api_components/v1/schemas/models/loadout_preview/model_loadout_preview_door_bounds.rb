# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # An oriented box around a closed door, in the hull holo's frame.
        class ModelLoadoutPreviewDoorBounds
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              center: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
              axes: {type: :array, items: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3}, minItems: 3, maxItems: 3, description: "The box's unit axes"},
              halfSize: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "Half the extent along each axis"}
            },
            additionalProperties: false,
            required: %w[center axes halfSize]
          })
        end
      end
    end
  end
end
