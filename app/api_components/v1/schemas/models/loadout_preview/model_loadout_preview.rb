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
              ports: {type: :array, items: ModelLoadoutPreviewPort},
              items: {type: :array, items: ModelLoadoutPreviewItem, description: "The holos of the parts the hull leaves out that its ports mount by default"},
              moduleHulls: {type: :array, items: ModelLoadoutPreviewModuleHull, description: "The hulls of the modules this ship's slots take"},
              servicingAreas: {type: :array, items: ModelLoadoutPreviewServicingArea},
              cargoGrids: {type: :array, items: ModelLoadoutPreviewCargoGrid},
              doors: {type: :array, items: ModelLoadoutPreviewDoor}
            },
            additionalProperties: false,
            required: %w[ports items moduleHulls servicingAreas cargoGrids doors]
          })
        end
      end
    end
  end
end
