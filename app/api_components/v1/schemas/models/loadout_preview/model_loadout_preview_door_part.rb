# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # One moving piece of a door. The hull holo names its node
        # `door_<door id>_<part>`, with `doorId` and `part` in its extras.
        class ModelLoadoutPreviewDoorPart
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              part: {type: :integer},
              object: {type: :string, description: "The piece's name in the game files"},
              keyframes: {type: :array, items: ModelLoadoutPreviewDoorKeyframe}
            },
            additionalProperties: false,
            required: %w[part object keyframes]
          })
        end
      end
    end
  end
end
