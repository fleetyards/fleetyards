# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # The holo of a part some port mounts by default.
        class ModelLoadoutPreviewItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              scKey: {type: :string},
              holoUrl: {type: :string}
            },
            additionalProperties: false,
            required: %w[scKey holoUrl]
          })
        end
      end
    end
  end
end
