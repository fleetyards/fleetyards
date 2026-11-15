# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # A door of the hull holo, which shows it closed.
        class ModelLoadoutPreviewDoor
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string},
              kind: {type: [:string, :null], description: "door, airlock, elevator, hatch, side_door, ..."},
              position: {type: [:array, :null], items: {type: :number}, minItems: 3, maxItems: 3},
              durationS: {type: :number, description: "Seconds the door takes to open"},
              bounds: {anyOf: [ModelLoadoutPreviewDoorBounds, {type: :null}]},
              parts: {type: :array, items: ModelLoadoutPreviewDoorPart}
            },
            additionalProperties: false,
            required: %w[id kind position durationS bounds parts]
          })
        end
      end
    end
  end
end
