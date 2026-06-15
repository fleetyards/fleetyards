# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventShipCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string},
            modelId: {type: :string, format: :uuid},
            classification: {type: :string},
            focus: {type: :string},
            minSize: {type: :string},
            maxSize: {type: :string},
            minCrew: {type: :integer},
            minCargo: {type: :number},
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
