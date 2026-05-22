# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class RefuelBoom
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            armName: {type: :string, nullable: true},
            armSize: {type: :string, nullable: true},
            nozzleName: {type: :string, nullable: true},
            nozzleSize: {type: :string, nullable: true},
            captureRadius: {type: :number, nullable: true},
            fuelFlowRate: {type: :number, nullable: true},
            quantumFuelFlowRate: {type: :number, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
