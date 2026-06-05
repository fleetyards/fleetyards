# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class RefuelBoom
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            armName: {type: :string},
            armSize: {type: :string},
            nozzleName: {type: :string},
            nozzleSize: {type: :string},
            captureRadius: {type: :number},
            fuelFlowRate: {type: :number},
            quantumFuelFlowRate: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
