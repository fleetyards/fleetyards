# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # Where a door part is at one point of opening, relative to where it
        # sits closed.
        class ModelLoadoutPreviewDoorKeyframe
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              t: {type: :number, description: "0 closed, 1 open"},
              translation: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
              rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"}
            },
            additionalProperties: false,
            required: %w[t translation rotation]
          })
        end
      end
    end
  end
end
