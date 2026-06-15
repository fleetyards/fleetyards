# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventShipCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: [:string, :null]},
            description: {type: [:string, :null]},
            modelId: {type: [:string, :null], format: :uuid},
            classification: {type: [:string, :null]},
            focus: {type: [:string, :null]},
            minSize: {type: [:string, :null]},
            maxSize: {type: [:string, :null]},
            minCrew: {type: [:integer, :null]},
            minCargo: {type: [:number, :null]},
            positionIds: {
              type: :array,
              items: {type: :string, format: :uuid}
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
