# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionShipUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: [:string, :null]},
            description: {type: [:string, :null]},
            modelId: {type: [:string, :null], format: :uuid},
            vehicleId: {
              type: [:string, :null],
              format: :uuid,
              description: "A member's own ship, which a flight's ship has to name; its model is taken from it"
            },
            classification: {type: [:string, :null]},
            foci: {type: :array, items: ::Shared::V1::Schemas::Enums::ModelFocusEnum},
            minSize: {type: [:string, :null]},
            maxSize: {type: [:string, :null]},
            minCrew: {type: [:integer, :null]},
            minCargo: {type: [:number, :null]},
            allowedModelIds: {
              type: :array,
              items: {type: :string, format: :uuid},
              description: "Models this spot will accept, when it names several rather than one"
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
