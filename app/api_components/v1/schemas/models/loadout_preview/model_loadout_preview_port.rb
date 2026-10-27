# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # One item port in the hull holo's frame: glTF Y-up, metres, origin at
        # the entity origin. A port with a parent is relative to the item
        # mounted on the last port before it with that name.
        class ModelLoadoutPreviewPort
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              parent: {type: [:string, :null]},
              helper: {type: :boolean, description: "False when the model has no node for the port, which then sits at the entity origin"},
              position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
              rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"},
              flags: {type: :string},
              editable: {type: :boolean},
              types: {type: :array, items: ModelLoadoutPreviewPortType},
              defaultItem: {type: [:string, :null], description: "scKey of the item mounted in the default loadout"},
              geometry: {type: :boolean, description: "False when the default item is drawn in neither holo"},
              stripped: {type: :boolean, description: "The default item is left out of the hull holo"},
              inParentHolo: {type: :boolean, description: "The default item is part of its parent item and drawn by the parent's holo"}
            },
            additionalProperties: false,
            required: %w[name parent helper position rotation flags editable types defaultItem geometry stripped inParentHolo]
          })
        end
      end
    end
  end
end
