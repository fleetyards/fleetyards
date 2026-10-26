# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # What a 3D loadout preview is put together from: the flight holo
        # without its swappable components, and where each item port sits on it.
        class ModelLoadoutPreview
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              holoHull: ::Shared::V1::Schemas::MediaFile,
              ports: {type: :array, items: ModelLoadoutPreviewPort}
            },
            additionalProperties: false,
            required: %w[ports]
          })
        end
      end
    end
  end
end
