# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class RefuelBoom
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            armName: {type: [:string, :null]},
            armSize: {type: [:string, :null]},
            nozzleName: {type: [:string, :null]},
            nozzleSize: {type: [:string, :null]},
            captureRadius: {type: [:number, :null]},
            fuelFlowRate: {type: [:number, :null]},
            quantumFuelFlowRate: {type: [:number, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
