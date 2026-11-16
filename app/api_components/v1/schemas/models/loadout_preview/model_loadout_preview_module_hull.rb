# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # A module drawn by its own hull holo in the slot it is fitted to: the
        # parts on its ports, its cargo grids and its doors are in its frame.
        class ModelLoadoutPreviewModuleHull
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              scKey: {type: :string, description: "The module part's game-file key, lowercased"},
              holoHullUrl: {type: :string},
              ports: {type: :array, items: ModelLoadoutPreviewPort},
              cargoGrids: {type: :array, items: ModelLoadoutPreviewCargoGrid},
              doors: {type: :array, items: ModelLoadoutPreviewDoor}
            },
            additionalProperties: false,
            required: %w[scKey holoHullUrl ports cargoGrids doors]
          })
        end
      end
    end
  end
end
