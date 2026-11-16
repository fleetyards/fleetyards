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
              bounds: {anyOf: [ModelLoadoutPreviewDoorBounds, {type: :null}], description: "Around every moving part of the closed door, hidden ones included"},
              outline: {anyOf: [ModelLoadoutPreviewDoorBounds, {type: :null}], description: "Around only what of the closed door shows from outside: what to point at"},
              outlineNodes: {type: :array, items: {type: :string}, description: "The hull holo's nodes that make up the visible door"},
              exterior: {type: :boolean, description: "An entrance from outside the ship, door port or not"},
              parts: {type: :array, items: ModelLoadoutPreviewDoorPart}
            },
            additionalProperties: false,
            required: %w[id kind position durationS bounds outline outlineNodes exterior parts]
          })
        end
      end
    end
  end
end
